defmodule SpazioSolazzo.BookingSystem.Changes.PreventDuplicateAsset do
  @moduledoc false

  use Ash.Resource.Change

  alias Ash.Changeset
  alias SpazioSolazzo.BookingSystem.Asset
  require Ash.Query

  @impl true
  def change(changeset, _opts, _context) do
    name = Ash.Changeset.get_attribute(changeset, :name)
    space_id = Ash.Changeset.get_attribute(changeset, :space_id)

    case Asset |> Ash.Query.filter(name == ^name and space_id == ^space_id) |> Ash.read() do
      {:ok, []} ->
        changeset

      {:ok, _} ->
        Changeset.add_error(changeset,
          field: :name,
          message: "asset with this name already exists for the space"
        )

      {:error, err} ->
        Changeset.add_error(changeset,
          field: :base,
          message: "failed to validate uniqueness: #{inspect(err)}"
        )
    end
  end
end
