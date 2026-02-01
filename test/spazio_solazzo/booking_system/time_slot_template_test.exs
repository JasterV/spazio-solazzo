defmodule SpazioSolazzo.BookingSystem.TimeSlotTemplateTest do
  use ExUnit.Case, async: true
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.create_space(
        "Test Space",
        "test-space",
        "Test description",
        10,
        12
      )

    %{space: space}
  end

  describe "create_time_slot_template/4" do
    test "creates a time slot template successfully", %{space: space} do
      assert {:ok, slot} =
               BookingSystem.create_time_slot_template(
                 ~T[09:00:00],
                 ~T[10:00:00],
                 :monday,
                 space.id
               )

      assert slot.start_time == ~T[09:00:00]
      assert slot.end_time == ~T[10:00:00]
      assert slot.day_of_week == :monday
      assert slot.space_id == space.id
    end

    test "creates templates for all days of the week", %{space: space} do
      days = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

      for day <- days do
        assert {:ok, slot} =
                 BookingSystem.create_time_slot_template(
                   ~T[09:00:00],
                   ~T[10:00:00],
                   day,
                   space.id
                 )

        assert slot.day_of_week == day
      end
    end

    test "prevents overlapping time slots on same day", %{space: space} do
      assert {:ok, _slot1} =
               BookingSystem.create_time_slot_template(
                 ~T[09:00:00],
                 ~T[11:00:00],
                 :monday,
                 space.id
               )

      assert {:error, error} =
               BookingSystem.create_time_slot_template(
                 ~T[10:00:00],
                 ~T[12:00:00],
                 :monday,
                 space.id
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "overlaps with existing time slot")
    end

    test "allows same time slot on different days", %{space: space} do
      assert {:ok, _slot1} =
               BookingSystem.create_time_slot_template(
                 ~T[09:00:00],
                 ~T[11:00:00],
                 :monday,
                 space.id
               )

      assert {:ok, slot2} =
               BookingSystem.create_time_slot_template(
                 ~T[09:00:00],
                 ~T[11:00:00],
                 :tuesday,
                 space.id
               )

      assert slot2.day_of_week == :tuesday
    end

    test "allows adjacent time slots on same day", %{space: space} do
      assert {:ok, _slot1} =
               BookingSystem.create_time_slot_template(
                 ~T[09:00:00],
                 ~T[11:00:00],
                 :monday,
                 space.id
               )

      assert {:ok, slot2} =
               BookingSystem.create_time_slot_template(
                 ~T[11:00:00],
                 ~T[13:00:00],
                 :monday,
                 space.id
               )

      assert slot2.start_time == ~T[11:00:00]
    end

    test "rejects invalid day of week", %{space: space} do
      assert {:error, error} =
               BookingSystem.create_time_slot_template(
                 ~T[09:00:00],
                 ~T[10:00:00],
                 :invalid_day,
                 space.id
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "atom must be one of")
    end

    test "rejects end time before start time", %{space: space} do
      assert {:error, error} =
               BookingSystem.create_time_slot_template(
                 ~T[10:00:00],
                 ~T[09:00:00],
                 :monday,
                 space.id
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "must be after start time")
    end

    test "rejects equal start and end times", %{space: space} do
      assert {:error, error} =
               BookingSystem.create_time_slot_template(
                 ~T[10:00:00],
                 ~T[10:00:00],
                 :monday,
                 space.id
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "must be after start time")
    end
  end

  describe "get_space_time_slots_by_date/2" do
    setup %{space: space} do
      {:ok, monday_morning} =
        BookingSystem.create_time_slot_template(
          ~T[09:00:00],
          ~T[13:00:00],
          :monday,
          space.id
        )

      {:ok, monday_afternoon} =
        BookingSystem.create_time_slot_template(
          ~T[14:00:00],
          ~T[18:00:00],
          :monday,
          space.id
        )

      {:ok, tuesday_slot} =
        BookingSystem.create_time_slot_template(
          ~T[09:00:00],
          ~T[13:00:00],
          :tuesday,
          space.id
        )

      %{
        monday_morning: monday_morning,
        monday_afternoon: monday_afternoon,
        tuesday_slot: tuesday_slot
      }
    end

    test "returns time slots for specific date's day of week", %{space: space} do
      monday_date = ~D[2026-02-02]
      assert Date.day_of_week(monday_date) == 1

      {:ok, slots} = BookingSystem.get_space_time_slots_by_date(space.id, monday_date)

      assert length(slots) == 2
      assert Enum.any?(slots, &(&1.start_time == ~T[09:00:00]))
      assert Enum.any?(slots, &(&1.start_time == ~T[14:00:00]))
    end

    test "returns different slots for different days", %{space: space} do
      tuesday_date = ~D[2026-02-03]
      assert Date.day_of_week(tuesday_date) == 2

      {:ok, slots} = BookingSystem.get_space_time_slots_by_date(space.id, tuesday_date)

      assert length(slots) == 1
      assert hd(slots).start_time == ~T[09:00:00]
    end

    test "returns empty list when no slots for that day", %{space: space} do
      wednesday_date = ~D[2026-02-04]
      assert Date.day_of_week(wednesday_date) == 3

      {:ok, slots} = BookingSystem.get_space_time_slots_by_date(space.id, wednesday_date)

      assert slots == []
    end

    test "handles all days of the week correctly", %{space: space} do
      days_and_dates = [
        {:monday, ~D[2026-02-02]},
        {:tuesday, ~D[2026-02-03]},
        {:wednesday, ~D[2026-02-04]},
        {:thursday, ~D[2026-02-05]},
        {:friday, ~D[2026-02-06]},
        {:saturday, ~D[2026-02-07]},
        {:sunday, ~D[2026-02-01]}
      ]

      for {day_atom, date} <- days_and_dates do
        BookingSystem.create_time_slot_template(
          ~T[20:00:00],
          ~T[21:00:00],
          day_atom,
          space.id
        )

        {:ok, slots} = BookingSystem.get_space_time_slots_by_date(space.id, date)
        assert Enum.any?(slots, &(&1.start_time == ~T[20:00:00]))
      end
    end

    test "only returns slots for specified space", %{space: space} do
      {:ok, other_space} =
        BookingSystem.create_space(
          "Other Space",
          "other-space",
          "Other description",
          5,
          5
        )

      {:ok, _other_slot} =
        BookingSystem.create_time_slot_template(
          ~T[20:00:00],
          ~T[22:00:00],
          :monday,
          other_space.id
        )

      monday_date = ~D[2026-02-02]
      {:ok, slots} = BookingSystem.get_space_time_slots_by_date(space.id, monday_date)

      assert Enum.all?(slots, &(&1.space_id == space.id))
      refute Enum.any?(slots, &(&1.start_time == ~T[20:00:00]))
    end
  end
end
