defmodule SpazioSolazzo.BookingSystem.Booking do
  @moduledoc """
  Represents a customer booking with state management for reservation lifecycle.
  """

  use Ash.Resource,
    otp_app: :spazio_solazzo,
    domain: SpazioSolazzo.BookingSystem,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub],
    extensions: [AshStateMachine]

  alias SpazioSolazzo.BookingSystem.Booking.EmailWorker

  postgres do
    table "bookings"
    repo SpazioSolazzo.Repo
  end

  state_machine do
    initial_states([:reserved])
    default_initial_state(:reserved)

    transitions do
      transition(:confirm_booking, from: :reserved, to: :completed)
      transition(:cancel, from: [:reserved], to: :cancelled)
    end
  end

  actions do
    defaults [:read]

    read :list_active_asset_bookings_by_date do
      argument :asset_id, :uuid, allow_nil?: false
      argument :date, :date, allow_nil?: false

      filter expr(
               asset_id == ^arg(:asset_id) and date == ^arg(:date) and
                 state in [:reserved, :completed]
             )
    end

    create :create do
      argument :time_slot_template_id, :uuid, allow_nil?: false
      argument :asset_id, :uuid, allow_nil?: false
      argument :date, :date, allow_nil?: false
      argument :customer_name, :string, allow_nil?: false
      argument :customer_email, :string, allow_nil?: false
      argument :customer_phone, :string, allow_nil?: false
      argument :customer_comment, :string, allow_nil?: true

      change manage_relationship(:time_slot_template_id, :time_slot_template,
               type: :append_and_remove
             )

      change manage_relationship(:asset_id, :asset, type: :append_and_remove)

      change fn changeset, _ctx ->
        template_id = Ash.Changeset.get_argument(changeset, :time_slot_template_id)

        case Ash.get(SpazioSolazzo.BookingSystem.TimeSlotTemplate, template_id) do
          {:ok, template} ->
            changeset
            |> Ash.Changeset.force_change_attribute(:start_time, template.start_time)
            |> Ash.Changeset.force_change_attribute(:end_time, template.end_time)
            |> Ash.Changeset.force_change_attribute(
              :date,
              Ash.Changeset.get_argument(changeset, :date)
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

          {:error, _} ->
            Ash.Changeset.add_error(changeset,
              field: :time_slot_template_id,
              message: "Template not found"
            )
        end
      end

      change after_action(fn _changeset, booking, _ctx ->
               %{
                 booking_id: booking.id,
                 customer_name: booking.customer_name,
                 customer_email: booking.customer_email,
                 customer_phone: booking.customer_phone,
                 customer_comment: booking.customer_comment,
                 date: Calendar.strftime(booking.date, "%A, %B %d"),
                 start_time: booking.start_time,
                 end_time: booking.end_time
               }
               |> EmailWorker.new()
               |> Oban.insert!()

               {:ok, booking}
             end)
    end

    update :confirm_booking do
      accept []
      change transition_state(:completed)
    end

    update :cancel do
      accept []
      change transition_state(:cancelled)
    end
  end

  pub_sub do
    module SpazioSolazzoWeb.Endpoint
    prefix "booking"

    publish :create, ["created"]
    publish :cancel, ["cancelled"]
  end

  attributes do
    uuid_primary_key :id
    attribute :date, :date, allow_nil?: false
    attribute :customer_name, :string, allow_nil?: false
    attribute :customer_email, :string, allow_nil?: false
    attribute :start_time, :time, allow_nil?: false
    attribute :end_time, :time, allow_nil?: false
    attribute :customer_phone, :string, allow_nil?: false
    attribute :customer_comment, :string, allow_nil?: true

    attribute :state, :atom do
      allow_nil? false
      default :reserved
      public? true
      constraints one_of: [:reserved, :completed, :cancelled]
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :asset, SpazioSolazzo.BookingSystem.Asset
    belongs_to :time_slot_template, SpazioSolazzo.BookingSystem.TimeSlotTemplate
  end
end
