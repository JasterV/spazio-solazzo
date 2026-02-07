defmodule SpazioSolazzo.BookingSystem.Booking do
  @moduledoc """
  Represents a customer booking with state management for reservation lifecycle.
  """

  use Ash.Resource,
    otp_app: :spazio_solazzo,
    domain: SpazioSolazzo.BookingSystem,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub],
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshStateMachine]

  require Ash.Query

  alias SpazioSolazzo.BookingSystem.Booking.{
    AdminActionEmailWorker,
    RequestCreatedEmailWorker,
    UserCancellationEmailWorker
  }

  postgres do
    table "bookings"
    repo SpazioSolazzo.Repo

    references do
      reference :user, on_delete: :nilify, index?: true
    end

    custom_indexes do
      # Composite index for space + datetime range queries (most common pattern)
      index [:space_id, :start_datetime, :end_datetime]

      # Composite index for space + state queries (filtering by status)
      index [:space_id, :state]

      # Single indexes for datetime overlap queries
      index [:start_datetime]
      index [:end_datetime]
    end
  end

  state_machine do
    initial_states([:requested])
    default_initial_state(:requested)

    transitions do
      transition(:approve, from: :requested, to: :accepted)
      transition(:reject, from: :requested, to: :rejected)
      transition(:cancel, from: [:requested, :accepted], to: :cancelled)
    end
  end

  actions do
    defaults [:read]

    read :search do
      description "Fetch bookings within a date/time range with optional filters"

      argument :space_id, :uuid, allow_nil?: true
      argument :start_datetime, :datetime, allow_nil?: false
      argument :end_datetime, :datetime, allow_nil?: false
      argument :states, {:array, :atom}, allow_nil?: true
      argument :select, {:array, :atom}, allow_nil?: true

      prepare fn query, _ctx ->
        start_dt = Ash.Query.get_argument(query, :start_datetime)
        end_dt = Ash.Query.get_argument(query, :end_datetime)

        # Base datetime overlap filter
        query =
          Ash.Query.filter(
            query,
            start_datetime < ^end_dt and end_datetime > ^start_dt
          )

        # Optional space filter
        query =
          case Ash.Query.get_argument(query, :space_id) do
            nil -> query
            space_id -> Ash.Query.filter(query, space_id == ^space_id)
          end

        # Optional states filter
        query =
          case Ash.Query.get_argument(query, :states) do
            nil -> query
            [] -> query
            states -> Ash.Query.filter(query, state in ^states)
          end

        case Ash.Query.get_argument(query, :select) do
          nil -> query
          [] -> query
          select -> Ash.Query.select(query, select)
        end
      end
    end

    read :read_pending_bookings do
      description "Fetch pending bookings for admin dashboard with pagination"

      argument :space_id, :uuid, allow_nil?: true
      argument :email, :string, allow_nil?: true
      argument :date, :date, allow_nil?: true

      # Only requested bookings
      filter expr(state == :requested)

      pagination do
        required? false
        offset? true
        countable true
        default_limit 10
        max_page_size 50
      end

      # Apply shared admin filters preparation
      prepare SpazioSolazzo.BookingSystem.Booking.Preparations.ApplyAdminFilters

      prepare fn query, _ctx ->
        Ash.Query.sort(query, inserted_at: :desc)
      end
    end

    read :read_booking_history do
      description "Fetch historical bookings (accepted/rejected/cancelled) with pagination"

      argument :space_id, :uuid, allow_nil?: true
      argument :email, :string, allow_nil?: true
      argument :date, :date, allow_nil?: true

      # Non-pending states
      filter expr(state in [:accepted, :rejected, :cancelled])

      pagination do
        required? false
        offset? true
        countable true
        default_limit 25
        max_page_size 100
      end

      # Apply shared admin filters preparation
      prepare SpazioSolazzo.BookingSystem.Booking.Preparations.ApplyAdminFilters

      prepare fn query, _ctx ->
        Ash.Query.sort(query, start_datetime: :desc)
      end
    end

    create :create do
      argument :space_id, :uuid, allow_nil?: false
      argument :user_id, :uuid, allow_nil?: true
      argument :date, :date, allow_nil?: false
      argument :start_time, :time, allow_nil?: false
      argument :end_time, :time, allow_nil?: false
      argument :customer_name, :string, allow_nil?: false
      argument :customer_email, :string, allow_nil?: false
      argument :customer_phone, :string, allow_nil?: true
      argument :customer_comment, :string, allow_nil?: true

      change manage_relationship(:space_id, :space, type: :append_and_remove)
      change manage_relationship(:user_id, :user, type: :append_and_remove, authorize?: false)

      validate {SpazioSolazzo.BookingSystem.Validations.FutureDate, field: :date}
      validate {SpazioSolazzo.BookingSystem.Validations.ChronologicalOrder, start: :start_time, end: :end_time}
      validate {SpazioSolazzo.BookingSystem.Validations.Email, field: :customer_email}

      change fn changeset, _ctx ->
        date = Ash.Changeset.get_argument(changeset, :date)
        start_time = Ash.Changeset.get_argument(changeset, :start_time)
        end_time = Ash.Changeset.get_argument(changeset, :end_time)

        start_datetime = DateTime.new!(date, start_time, "Etc/UTC")
        end_datetime = DateTime.new!(date, end_time, "Etc/UTC")

        changeset
        |> Ash.Changeset.force_change_attribute(:start_datetime, start_datetime)
        |> Ash.Changeset.force_change_attribute(:end_datetime, end_datetime)
        |> Ash.Changeset.force_change_attribute(:date, date)
        |> Ash.Changeset.force_change_attribute(:start_time, start_time)
        |> Ash.Changeset.force_change_attribute(:end_time, end_time)
        |> Ash.Changeset.force_change_attribute(
          :customer_name,
          Ash.Changeset.get_argument(changeset, :customer_name)
        )
        |> Ash.Changeset.force_change_attribute(
          :customer_email,
          Ash.Changeset.get_argument(changeset, :customer_email)
        )
        |> Ash.Changeset.force_change_attribute(
          :customer_phone,
          Ash.Changeset.get_argument(changeset, :customer_phone)
        )
        |> Ash.Changeset.force_change_attribute(
          :customer_comment,
          Ash.Changeset.get_argument(changeset, :customer_comment)
        )
      end

      change after_action(fn _changeset, booking, _ctx ->
               booking = Ash.load!(booking, [:space])

               %{
                 booking_id: booking.id,
                 customer_name: booking.customer_name,
                 customer_email: booking.customer_email,
                 customer_phone: booking.customer_phone,
                 customer_comment: booking.customer_comment,
                 space_name: booking.space.name,
                 start_datetime: booking.start_datetime,
                 end_datetime: booking.end_datetime
               }
               |> RequestCreatedEmailWorker.new()
               |> Oban.insert!()

               {:ok, booking}
             end)
    end

    create :create_walk_in do
      argument :space_id, :uuid, allow_nil?: false
      argument :start_datetime, :datetime, allow_nil?: false
      argument :end_datetime, :datetime, allow_nil?: false
      argument :customer_name, :string, allow_nil?: false
      argument :customer_email, :string, allow_nil?: false
      argument :customer_phone, :string, allow_nil?: true

      change manage_relationship(:space_id, :space, type: :append_and_remove)

      validate {SpazioSolazzo.BookingSystem.Validations.FutureDate, field: :end_datetime}
      validate {SpazioSolazzo.BookingSystem.Validations.ChronologicalOrder, start: :start_datetime, end: :end_datetime}
      validate {SpazioSolazzo.BookingSystem.Validations.Email, field: :customer_email}

      change fn changeset, _ctx ->
        start_datetime = Ash.Changeset.get_argument(changeset, :start_datetime)
        end_datetime = Ash.Changeset.get_argument(changeset, :end_datetime)

        date = DateTime.to_date(start_datetime)
        start_time = DateTime.to_time(start_datetime)
        end_time = DateTime.to_time(end_datetime)

        changeset
        |> Ash.Changeset.force_change_attribute(:start_datetime, start_datetime)
        |> Ash.Changeset.force_change_attribute(:end_datetime, end_datetime)
        |> Ash.Changeset.force_change_attribute(:date, date)
        |> Ash.Changeset.force_change_attribute(:start_time, start_time)
        |> Ash.Changeset.force_change_attribute(:end_time, end_time)
        |> Ash.Changeset.force_change_attribute(:state, :accepted)
        |> Ash.Changeset.force_change_attribute(
          :customer_name,
          Ash.Changeset.get_argument(changeset, :customer_name)
        )
        |> Ash.Changeset.force_change_attribute(
          :customer_email,
          Ash.Changeset.get_argument(changeset, :customer_email)
        )
        |> Ash.Changeset.force_change_attribute(
          :customer_phone,
          Ash.Changeset.get_argument(changeset, :customer_phone)
        )
      end
    end

    update :approve do
      accept []
      require_atomic? false
      change transition_state(:accepted)

      change after_action(fn _changeset, booking, _ctx ->
               booking = Ash.load!(booking, [:space])

               %{
                 booking_id: booking.id,
                 customer_name: booking.customer_name,
                 customer_email: booking.customer_email,
                 customer_phone: booking.customer_phone,
                 space_name: booking.space.name,
                 start_datetime: booking.start_datetime,
                 end_datetime: booking.end_datetime,
                 action: "accepted"
               }
               |> AdminActionEmailWorker.new()
               |> Oban.insert!()

               {:ok, booking}
             end)
    end

    update :reject do
      accept [:rejection_reason]
      argument :reason, :string, allow_nil?: false
      require_atomic? false

      change fn changeset, _ctx ->
        reason = Ash.Changeset.get_argument(changeset, :reason)
        Ash.Changeset.force_change_attribute(changeset, :rejection_reason, reason)
      end

      change transition_state(:rejected)

      change after_action(fn _changeset, booking, _ctx ->
               booking = Ash.load!(booking, [:space])

               %{
                 customer_name: booking.customer_name,
                 customer_email: booking.customer_email,
                 customer_phone: booking.customer_phone,
                 space_name: booking.space.name,
                 start_datetime: booking.start_datetime,
                 end_datetime: booking.end_datetime,
                 action: "rejected",
                 rejection_reason: booking.rejection_reason
               }
               |> AdminActionEmailWorker.new()
               |> Oban.insert!()

               {:ok, booking}
             end)
    end

    update :cancel do
      accept [:cancellation_reason]
      argument :reason, :string, allow_nil?: false
      require_atomic? false

      change fn changeset, _ctx ->
        reason = Ash.Changeset.get_argument(changeset, :reason)
        Ash.Changeset.force_change_attribute(changeset, :cancellation_reason, reason)
      end

      change transition_state(:cancelled)

      change after_action(fn _changeset, booking, _ctx ->
               booking = Ash.load!(booking, [:space])

               %{
                 customer_name: booking.customer_name,
                 customer_email: booking.customer_email,
                 customer_phone: booking.customer_phone,
                 space_name: booking.space.name,
                 start_datetime: booking.start_datetime,
                 end_datetime: booking.end_datetime,
                 cancellation_reason: booking.cancellation_reason
               }
               |> UserCancellationEmailWorker.new()
               |> Oban.insert!()

               {:ok, booking}
             end)
    end

    destroy :destroy do
      description "Delete a booking record"
      primary? true
    end
  end

  policies do
    policy action([:cancel, :approve, :reject]) do
      authorize_if always()
    end

    policy action_type(:destroy) do
      authorize_if expr(:user_id == ^actor(:id))
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if always()
    end
  end

  pub_sub do
    module SpazioSolazzoWeb.Endpoint
    prefix "booking"

    publish :create, ["created"]
    publish :create_walk_in, ["created"]
    publish :approve, ["approved"]
    publish :reject, ["rejected"]
    publish :cancel, ["cancelled"]
  end

  attributes do
    uuid_primary_key :id
    attribute :start_datetime, :datetime, allow_nil?: false
    attribute :end_datetime, :datetime, allow_nil?: false
    attribute :date, :date, allow_nil?: false
    attribute :customer_name, :string, allow_nil?: false
    attribute :customer_email, :string, allow_nil?: false
    attribute :start_time, :time, allow_nil?: false
    attribute :end_time, :time, allow_nil?: false
    attribute :customer_phone, :string, allow_nil?: true
    attribute :customer_comment, :string, allow_nil?: true
    attribute :cancellation_reason, :string, allow_nil?: true
    attribute :rejection_reason, :string, allow_nil?: true

    attribute :state, :atom do
      allow_nil? false
      default :requested
      public? true
      constraints one_of: [:requested, :accepted, :rejected, :cancelled]
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :space, SpazioSolazzo.BookingSystem.Space do
      allow_nil? false
      public? true
    end

    belongs_to :user, SpazioSolazzo.Accounts.User do
      allow_nil? true
    end
  end
end
