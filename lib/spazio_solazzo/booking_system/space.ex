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
    defaults [:read]

    create :create do
      accept [:name, :description, :slug, :public_capacity, :real_capacity]

      validate fn changeset, _ctx ->
        real_capacity = Ash.Changeset.get_attribute(changeset, :real_capacity)
        public_capacity = Ash.Changeset.get_attribute(changeset, :public_capacity)

        cond do
          real_capacity && real_capacity <= 0 ->
            {:error, field: :real_capacity, message: "must be greater than 0"}

          public_capacity && public_capacity <= 0 ->
            {:error, field: :public_capacity, message: "must be greater than 0"}

          real_capacity && public_capacity && public_capacity > real_capacity ->
            {:error,
             field: :public_capacity, message: "must be less than or equal to real_capacity"}

          true ->
            :ok
        end
      end
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :description, :string, allow_nil?: false, public?: true
    attribute :slug, :string, allow_nil?: false, public?: true
    attribute :public_capacity, :integer, allow_nil?: false, public?: true
    attribute :real_capacity, :integer, allow_nil?: false, public?: true
  end

  identities do
    identity :unique_name, [:name]
    identity :unique_slug, [:slug]
  end
end
