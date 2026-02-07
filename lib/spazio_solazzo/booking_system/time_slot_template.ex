defmodule SpazioSolazzo.BookingSystem.TimeSlotTemplate do
  @moduledoc """
  Defines recurring time slots for bookings based on day of the week.
  """

  use Ash.Resource,
    otp_app: :spazio_solazzo,
    domain: SpazioSolazzo.BookingSystem,
    data_layer: AshPostgres.DataLayer

  alias SpazioSolazzo.BookingSystem.TimeSlotTemplate.Changes

  postgres do
    table "time_slot_templates"
    repo SpazioSolazzo.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:start_time, :end_time, :space_id, :day_of_week]

      validate {SpazioSolazzo.BookingSystem.Validations.ChronologicalOrder,
                start: :start_time, end: :end_time}

      change {Changes.PreventCreationOverlap, []}
    end

    read :get_space_time_slots_by_date do
      argument :space_id, :string do
        allow_nil? false
      end

      argument :date, :date do
        allow_nil? false
      end

      filter expr(space_id == ^arg(:space_id))
      prepare SpazioSolazzo.BookingSystem.TimeSlotTemplate.Preparations.FilterByDate
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :start_time, :time, allow_nil?: false, public?: true
    attribute :end_time, :time, allow_nil?: false, public?: true

    attribute :day_of_week, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    end
  end

  relationships do
    belongs_to :space, SpazioSolazzo.BookingSystem.Space do
      allow_nil? false
      public? true
    end
  end

  calculations do
    calculate :booking_stats,
              :map,
              {SpazioSolazzo.BookingSystem.TimeSlotTemplate.Calculations.SlotBookingStats, []} do
      description "Calculates booking counts and availability for this time slot on a specific date"

      argument :date, :date, allow_nil?: false
      argument :space_id, :uuid, allow_nil?: false
      argument :capacity, :integer, allow_nil?: false
      argument :user_id, :uuid, allow_nil?: true
    end
  end
end
