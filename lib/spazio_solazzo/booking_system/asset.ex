defmodule SpazioSolazzo.BookingSystem.Asset do
  use Ash.Resource,
    otp_app: :spazio_solazzo,
    domain: SpazioSolazzo.BookingSystem,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "assets"
    repo SpazioSolazzo.Repo
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:name, :space_id]
      change SpazioSolazzo.BookingSystem.Changes.PreventDuplicateAsset
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :space, SpazioSolazzo.BookingSystem.Space do
      allow_nil? false
      public? true
    end
  end

  identities do
    identity :unique_name_per_space, [:name, :space_id]
  end
end
