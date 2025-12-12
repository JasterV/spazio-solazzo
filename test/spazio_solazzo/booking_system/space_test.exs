defmodule SpazioSolazzo.BookingSystem.SpaceTest do
  use ExUnit.Case
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  test "creates a space" do
    {:ok, space} =
      BookingSystem.Space
      |> Ash.Changeset.for_create(:create, %{name: "Space", slug: "space", description: "test"})
      |> Ash.create()

    assert space.name == "Space"
    assert space.slug == "space"
  end
end
