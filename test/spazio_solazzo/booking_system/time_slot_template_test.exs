defmodule SpazioSolazzo.BookingSystem.TimeSlotTemplateTest do
  use ExUnit.Case
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.Space
      |> Ash.Changeset.for_create(:create, %{name: "Test", slug: "test", description: "desc"})
      |> Ash.create()

    %{space: space}
  end

  test "prevents overlapping time slot templates for same space", %{space: space} do
    assert {:ok, _} =
             BookingSystem.TimeSlotTemplate
             |> Ash.Changeset.for_create(:create, %{
               name: "Morning",
               start_time: ~T[09:00:00],
               end_time: ~T[12:00:00],
               space_id: space.id,
               day_of_week: :monday
             })
             |> Ash.create()

    assert {:error, changeset} =
             BookingSystem.TimeSlotTemplate
             |> Ash.Changeset.for_create(:create, %{
               name: "Overlap",
               start_time: ~T[11:00:00],
               end_time: ~T[13:00:00],
               space_id: space.id,
               day_of_week: :monday
             })
             |> Ash.create()

    assert Ash.Error.error_descriptions(changeset.errors) =~ "overlaps"
  end

  test "allows non-overlapping time slot templates for same space", %{space: space} do
    assert {:ok, _} =
             BookingSystem.TimeSlotTemplate
             |> Ash.Changeset.for_create(:create, %{
               name: "Morning",
               start_time: ~T[09:00:00],
               end_time: ~T[12:00:00],
               space_id: space.id,
               day_of_week: :monday
             })
             |> Ash.create()

    assert {:ok, _} =
             BookingSystem.TimeSlotTemplate
             |> Ash.Changeset.for_create(:create, %{
               name: "Afternoon",
               start_time: ~T[13:00:00],
               end_time: ~T[16:00:00],
               space_id: space.id,
               day_of_week: :monday
             })
             |> Ash.create()
  end
end
