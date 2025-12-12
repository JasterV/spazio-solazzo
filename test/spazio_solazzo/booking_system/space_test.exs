defmodule SpazioSolazzo.BookingSystem.SpaceTest do
  use ExUnit.Case
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  test "prevents duplicate names and slugs" do
    params = %{name: "Space", slug: "space", description: "test"}

    assert {:ok, _} =
             BookingSystem.Space
             |> Ash.Changeset.for_create(:create, params)
             |> Ash.create()

    assert {:error, error} =
             BookingSystem.Space
             |> Ash.Changeset.for_create(:create, params)
             |> Ash.create()

    error_messages = Ash.Error.error_descriptions(error)

    assert String.contains?(error_messages, "unique") or
             String.contains?(error_messages, "unique constraint")
  end
end
