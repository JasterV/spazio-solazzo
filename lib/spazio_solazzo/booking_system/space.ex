defmodule SpazioSolazzo.BookingSystem.Space do
  @moduledoc """
  Represents a physical or virtual space that contains bookable assets.
  """

  use Ash.Resource,
    otp_app: :spazio_solazzo,
    domain: SpazioSolazzo.BookingSystem,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "spaces"
    repo SpazioSolazzo.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:name, :description, :slug, :capacity]

      validate fn changeset, _ctx ->
        capacity = Ash.Changeset.get_attribute(changeset, :capacity)

        if capacity && capacity <= 0 do
          {:error, field: :capacity, message: "must be greater than 0"}
        else
          :ok
        end
      end
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :description, :string, allow_nil?: false, public?: true
    attribute :slug, :string, allow_nil?: false, public?: true
    attribute :capacity, :integer, allow_nil?: false, public?: true
  end

  identities do
    identity :unique_name, [:name]
    identity :unique_slug, [:slug]
  end
end
