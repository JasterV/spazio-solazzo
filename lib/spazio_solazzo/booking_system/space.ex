defmodule SpazioSolazzo.BookingSystem.Space do
  @moduledoc """
  Represents a physical or virtual space that contains bookable assets.
  """

  use Ash.Resource,
    otp_app: :spazio_solazzo,
    domain: SpazioSolazzo.BookingSystem,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "spaces"
    repo SpazioSolazzo.Repo
  end

  actions do
    defaults [:read, create: :*]
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :description, :string, allow_nil?: false, public?: true
    attribute :slug, :string, allow_nil?: false, public?: true
  end

  identities do
    identity :unique_name, [:name]
    identity :unique_slug, [:slug]
  end
end
