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

    read :list_accepted_space_bookings_by_date do
      argument :space_id, :uuid, allow_nil?: false
      argument :date, :date, allow_nil?: false

      filter expr(
               space_id == ^arg(:space_id) and date == ^arg(:date) and
                 state == :accepted
             )
    end

    read :list_booking_requests do
      argument :space_id, :uuid, allow_nil?: true
      argument :email, :string, allow_nil?: true
      argument :date, :date, allow_nil?: true

      filter expr(state == :requested or state == :accepted)

      prepare fn query, _ctx ->
        query =
          case Ash.Query.get_argument(query, :space_id) do
            nil -> query
            space_id -> Ash.Query.filter(query, space_id == ^space_id)
          end

        query =
          case Ash.Query.get_argument(query, :email) do
            nil -> query
            email -> Ash.Query.filter(query, customer_email == ^email)
          end

        case Ash.Query.get_argument(query, :date) do
          nil -> query
          date -> Ash.Query.filter(query, date == ^date)
        end
      end
    end

    read :count_pending_requests do
      filter expr(state == :requested)
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

      validate fn changeset, _ctx ->
        date = Ash.Changeset.get_argument(changeset, :date)
        today = Date.utc_today()

        if date && Date.compare(date, today) == :lt do
          {:error, field: :date, message: "cannot be in the past"}
        else
          :ok
        end
      end

      validate fn changeset, _ctx ->
        start_time = Ash.Changeset.get_argument(changeset, :start_time)
        end_time = Ash.Changeset.get_argument(changeset, :end_time)

        if start_time && end_time && Time.compare(end_time, start_time) != :gt do
          {:error, field: :end_time, message: "must be after start time"}
        else
          :ok
        end
      end

      validate fn changeset, _ctx ->
        email = Ash.Changeset.get_argument(changeset, :customer_email)

        if email && !String.match?(email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/) do
          {:error, field: :customer_email, message: "must be a valid email"}
        else
          :ok
        end
      end

      change fn changeset, _ctx ->
        changeset
        |> Ash.Changeset.force_change_attribute(
          :date,
          Ash.Changeset.get_argument(changeset, :date)
        )
        |> Ash.Changeset.force_change_attribute(
          :start_time,
          Ash.Changeset.get_argument(changeset, :start_time)
        )
        |> Ash.Changeset.force_change_attribute(
          :end_time,
          Ash.Changeset.get_argument(changeset, :end_time)
        )
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
                 date: Calendar.strftime(booking.date, "%A, %B %d"),
                 start_time: booking.start_time,
                 end_time: booking.end_time
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
      argument :customer_comment, :string, allow_nil?: true

      change manage_relationship(:space_id, :space, type: :append_and_remove)

      validate fn changeset, _ctx ->
        start_datetime = Ash.Changeset.get_argument(changeset, :start_datetime)
        now = DateTime.utc_now()

        if start_datetime && DateTime.compare(start_datetime, now) == :lt do
          {:error, field: :start_datetime, message: "cannot be in the past"}
        else
          :ok
        end
      end

      validate fn changeset, _ctx ->
        start_datetime = Ash.Changeset.get_argument(changeset, :start_datetime)
        end_datetime = Ash.Changeset.get_argument(changeset, :end_datetime)

        if start_datetime && end_datetime &&
             DateTime.compare(end_datetime, start_datetime) != :gt do
          {:error, field: :end_datetime, message: "must be after start datetime"}
        else
          :ok
        end
      end

      validate fn changeset, _ctx ->
        email = Ash.Changeset.get_argument(changeset, :customer_email)

        if email && !String.match?(email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/) do
          {:error, field: :customer_email, message: "must be a valid email"}
        else
          :ok
        end
      end

      change fn changeset, _ctx ->
        start_datetime = Ash.Changeset.get_argument(changeset, :start_datetime)
        end_datetime = Ash.Changeset.get_argument(changeset, :end_datetime)

        date = DateTime.to_date(start_datetime)
        start_time = DateTime.to_time(start_datetime)
        end_time = DateTime.to_time(end_datetime)

        changeset
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
        |> Ash.Changeset.force_change_attribute(
          :customer_comment,
          Ash.Changeset.get_argument(changeset, :customer_comment)
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
                 date: Calendar.strftime(booking.date, "%A, %B %d"),
                 start_time: booking.start_time,
                 end_time: booking.end_time,
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
                 date: Calendar.strftime(booking.date, "%A, %B %d"),
                 start_time: booking.start_time,
                 end_time: booking.end_time,
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
                 date: Calendar.strftime(booking.date, "%A, %B %d"),
                 start_time: booking.start_time,
                 end_time: booking.end_time,
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

    action :get_slot_booking_counts, :map do
      argument :space_id, :uuid, allow_nil?: true
      argument :date, :date, allow_nil?: false
      argument :start_time, :time, allow_nil?: false
      argument :end_time, :time, allow_nil?: false

      run fn input, _context ->
        space_id = input.arguments.space_id
        date = input.arguments.date
        start_time = input.arguments.start_time
        end_time = input.arguments.end_time

        query =
          __MODULE__
          |> Ash.Query.filter(date == ^date)
          |> Ash.Query.filter(state == :requested or state == :accepted)

        query =
          if space_id do
            Ash.Query.filter(query, space_id == ^space_id)
          else
            query
          end

        case Ash.read(query) do
          {:ok, bookings} ->
            # Filter overlapping bookings
            overlapping_bookings =
              Enum.filter(bookings, fn booking ->
                Time.compare(booking.start_time, end_time) == :lt and
                  Time.compare(start_time, booking.end_time) == :lt
              end)

            pending_count = Enum.count(overlapping_bookings, &(&1.state == :requested))
            approved_count = Enum.count(overlapping_bookings, &(&1.state == :accepted))

            {:ok, %{pending: pending_count, approved: approved_count}}

          error ->
            error
        end
      end
    end
  end

  policies do
    policy action([:cancel, :approve, :reject, :get_slot_booking_counts]) do
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
    publish :approve, ["approved"]
    publish :reject, ["rejected"]
    publish :cancel, ["cancelled"]
  end

  attributes do
    uuid_primary_key :id
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
