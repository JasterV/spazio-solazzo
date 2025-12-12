defmodule SpazioSolazzo.BookingSystem.AssetTest do
  use ExUnit.Case
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.Space
      |> Ash.Changeset.for_create(:create, %{
        name: "AssetSpace",
        slug: "assetspace",
        description: "desc"
      })
      |> Ash.create()

    %{space: space}
  end

  test "prevents duplicate asset names within the system", %{space: space} do
    params = %{name: "T1", space_id: space.id}

    assert {:ok, _} =
             BookingSystem.Asset
             |> Ash.Changeset.for_create(:create, params)
             |> Ash.create()

    assert {:error, error} =
             BookingSystem.Asset
             |> Ash.Changeset.for_create(:create, params)
             |> Ash.create()

    message = Ash.Error.error_descriptions(error)

    assert String.contains?(message, "asset with this name already exists for the space") or
             String.contains?(message, "unique") or String.contains?(message, "unique constraint")
  end

  test "allows same asset name for different spaces", %{space: space} do
    params = %{name: "T1", space_id: space.id}

    assert {:ok, _} =
             BookingSystem.Asset
             |> Ash.Changeset.for_create(:create, params)
             |> Ash.create()

    # create another space
    {:ok, other_space} =
      BookingSystem.Space
      |> Ash.Changeset.for_create(:create, %{
        name: "OtherSpace",
        slug: "otherspace",
        description: "desc"
      })
      |> Ash.create()

    # same name in different space should succeed
    assert {:ok, _} =
             BookingSystem.Asset
             |> Ash.Changeset.for_create(:create, %{name: "T1", space_id: other_space.id})
             |> Ash.create()
  end
end
