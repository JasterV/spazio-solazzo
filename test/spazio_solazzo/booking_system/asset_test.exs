defmodule SpazioSolazzo.BookingSystem.AssetTest do
  use ExUnit.Case
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.BookingSystem.Asset

  setup do
    {:ok, space} = BookingSystem.create_space("AssetSpace", "assetspace", "desc")
    %{space: space}
  end

  test "prevents duplicate asset names within the system", %{space: space} do
    assert {:ok, _} = BookingSystem.create_asset("T1", space.id)
    assert {:error, error} = BookingSystem.create_asset("T1", space.id)

    message = Ash.Error.error_descriptions(error)

    assert String.contains?(message, "already been taken")
  end

  test "allows same asset name for different spaces", %{space: space} do
    assert {:ok, _} = BookingSystem.create_asset("T1", space.id)

    # create another space
    {:ok, other_space} = BookingSystem.create_space("OtherSpace", "otherspace", "desc")

    # same name in different space should succeed
    assert {:ok, _} = BookingSystem.create_asset("T1", other_space.id)
  end

  test "can get single asset by space id", %{space: space} do
    assert {:ok, expected_asset} = BookingSystem.create_asset("T1", space.id)
    assert {:ok, asset} = BookingSystem.get_asset_by_space_id(space.id)
    assert asset.id == expected_asset.id
  end

  test "can get multiple assets by space id", %{space: space} do
    assert {:ok, _} = BookingSystem.create_asset("T1", space.id)
    assert {:ok, _} = BookingSystem.create_asset("T2", space.id)
    assert {:ok, _} = BookingSystem.create_asset("T3", space.id)

    assert {:ok,
            [
              %Asset{name: "T1"},
              %Asset{name: "T2"},
              %Asset{name: "T3"}
            ]} =
             BookingSystem.get_space_assets(space.id)
  end
end
