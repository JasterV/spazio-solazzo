defmodule SpazioSolazzo.BookingSystem.TimeSlotTemplateTest do
  use ExUnit.Case, async: true
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} = BookingSystem.create_space("Test", "test", "description")
    %{space: space}
  end

  test "prevents overlapping time slot templates for same space", %{space: space} do
    assert {:ok, _} =
             BookingSystem.create_time_slot_template(
               ~T[09:00:00],
               ~T[12:00:00],
               :monday,
               space.id
             )

    assert {:error, changeset} =
             BookingSystem.create_time_slot_template(
               ~T[11:00:00],
               ~T[13:00:00],
               :monday,
               space.id
             )

    assert Ash.Error.error_descriptions(changeset.errors) =~ "overlaps"
  end

  test "allows non-overlapping time slot templates for same space on the same day", %{
    space: space
  } do
    assert {:ok, _} =
             BookingSystem.create_time_slot_template(
               ~T[09:00:00],
               ~T[12:00:00],
               :monday,
               space.id
             )

    assert {:ok, _} =
             BookingSystem.create_time_slot_template(
               ~T[13:00:00],
               ~T[16:00:00],
               :monday,
               space.id
             )
  end

  test "allows overlapping time slot templates for same space on different days", %{space: space} do
    assert {:ok, _} =
             BookingSystem.create_time_slot_template(
               ~T[09:00:00],
               ~T[12:00:00],
               :monday,
               space.id
             )

    assert {:ok, _} =
             BookingSystem.create_time_slot_template(
               ~T[09:00:00],
               ~T[12:00:00],
               :tuesday,
               space.id
             )
  end
end
