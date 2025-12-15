defmodule SpazioSolazzo.BookingSystem.SpaceTest do
  use ExUnit.Case
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  test "can create a space" do
    assert {:ok, _} =
             BookingSystem.create_space("Space", "space", "test description")

    assert {:ok, space} = BookingSystem.get_space_by_slug("space")

    assert space.slug == "space"
  end

  test "can't create two spaces with same name and slug" do
    assert {:ok, _} = BookingSystem.create_space("Space", "space", "test description")
    assert {:error, error} = BookingSystem.create_space("Space", "space", "test description")

    error_messages = Ash.Error.error_descriptions(error)

    assert String.contains?(error_messages, "has already been")
  end
end
