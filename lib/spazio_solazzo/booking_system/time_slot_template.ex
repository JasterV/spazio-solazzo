defmodule SpazioSolazzo.BookingSystem.TimeSlotTemplate do
  use Ash.Resource,
    otp_app: :spazio_solazzo,
    domain: SpazioSolazzo.BookingSystem,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "time_slot_templates"
    repo SpazioSolazzo.Repo
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:name, :start_time, :end_time, :space_id]
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :start_time, :time, allow_nil?: false, public?: true
    attribute :end_time, :time, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :space, SpazioSolazzo.BookingSystem.Space do
      allow_nil? false
      public? true
    end
  end
end
