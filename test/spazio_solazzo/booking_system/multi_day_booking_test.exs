defmodule SpazioSolazzo.BookingSystem.MultiDayBookingTest do
  @moduledoc """
  Tests for multi-day booking functionality using datetime fields.
  Verifies that bookings can span multiple days and that datetime range
  queries work correctly for availability checking and listing.
  """

  use SpazioSolazzo.DataCase, async: true

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.create_space(
        "Coworking",
        "coworking",
        "Coworking space for testing",
        5
      )

    %{space: space}
  end

  describe "multi-day walk-in bookings" do
    test "can create a multi-day booking spanning 3 days", %{space: space} do
      start_date = Date.add(Date.utc_today(), 1)
      end_date = Date.add(Date.utc_today(), 3)

      start_datetime = DateTime.new!(start_date, ~T[09:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(end_date, ~T[18:00:00], "Etc/UTC")

      {:ok, booking} =
        BookingSystem.create_walk_in(
          space.id,
          start_datetime,
          end_datetime,
          "John Doe",
          "john@example.com",
          nil,
          nil
        )

      assert booking.start_datetime == start_datetime
      assert booking.end_datetime == end_datetime
      assert booking.state == :accepted
      assert booking.customer_name == "John Doe"
    end

    test "multi-day booking appears in queries for all days it spans", %{space: space} do
      start_date = Date.add(Date.utc_today(), 1)
      end_date = Date.add(Date.utc_today(), 4)

      start_datetime = DateTime.new!(start_date, ~T[10:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(end_date, ~T[17:00:00], "Etc/UTC")

      {:ok, _booking} =
        BookingSystem.create_walk_in(
          space.id,
          start_datetime,
          end_datetime,
          "Jane Smith",
          "jane@example.com",
          nil,
          nil
        )

      # Should appear on start date
      {:ok, day1_bookings} =
        BookingSystem.list_accepted_space_bookings_by_date(space.id, start_date)

      assert length(day1_bookings) == 1

      # Should appear on middle date
      middle_date = Date.add(start_date, 1)

      {:ok, day2_bookings} =
        BookingSystem.list_accepted_space_bookings_by_date(space.id, middle_date)

      assert length(day2_bookings) == 1

      # Should appear on end date
      {:ok, day4_bookings} =
        BookingSystem.list_accepted_space_bookings_by_date(space.id, end_date)

      assert length(day4_bookings) == 1

      # Should not appear on day after end date
      day_after = Date.add(end_date, 1)

      {:ok, day_after_bookings} =
        BookingSystem.list_accepted_space_bookings_by_date(space.id, day_after)

      assert length(day_after_bookings) == 0
    end

    test "multi-day booking correctly counts toward availability on all days", %{space: space} do
      start_date = Date.add(Date.utc_today(), 1)
      end_date = Date.add(Date.utc_today(), 3)

      start_datetime = DateTime.new!(start_date, ~T[09:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(end_date, ~T[18:00:00], "Etc/UTC")

      {:ok, _booking} =
        BookingSystem.create_walk_in(
          space.id,
          start_datetime,
          end_datetime,
          "Test User",
          "test@example.com",
          nil,
          nil
        )

      # Check availability on start date
      {:ok, availability_day1} =
        BookingSystem.check_availability(space.id, start_date, ~T[10:00:00], ~T[16:00:00])

      # Should show reduced availability due to the multi-day booking
      assert availability_day1 in [:available, :over_public_capacity]

      # Check availability on middle date
      middle_date = Date.add(start_date, 1)

      {:ok, availability_day2} =
        BookingSystem.check_availability(space.id, middle_date, ~T[10:00:00], ~T[16:00:00])

      assert availability_day2 in [:available, :over_public_capacity]

      # Check availability on end date
      {:ok, availability_day3} =
        BookingSystem.check_availability(space.id, end_date, ~T[10:00:00], ~T[16:00:00])

      assert availability_day3 in [:available, :over_public_capacity]
    end

    test "multiple overlapping multi-day bookings correctly fill capacity", %{space: space} do
      start_date = Date.add(Date.utc_today(), 1)
      end_date = Date.add(Date.utc_today(), 3)

      # Create 5 multi-day bookings (public capacity)
      for i <- 1..5 do
        start_datetime = DateTime.new!(start_date, ~T[09:00:00], "Etc/UTC")
        end_datetime = DateTime.new!(end_date, ~T[18:00:00], "Etc/UTC")

        {:ok, _booking} =
          BookingSystem.create_walk_in(
            space.id,
            start_datetime,
            end_datetime,
            "User #{i}",
            "user#{i}@example.com",
            nil,
            nil
          )
      end

      # Check that public capacity is reached on middle day
      middle_date = Date.add(start_date, 1)

      {:ok, availability} =
        BookingSystem.check_availability(space.id, middle_date, ~T[10:00:00], ~T[16:00:00])

      assert availability == :over_capacity
    end

    test "can have both single-day and multi-day bookings on the same day", %{space: space} do
      date = Date.add(Date.utc_today(), 1)

      # Create a multi-day booking
      multi_start = DateTime.new!(date, ~T[09:00:00], "Etc/UTC")
      multi_end = DateTime.new!(Date.add(date, 2), ~T[18:00:00], "Etc/UTC")

      {:ok, _multi_booking} =
        BookingSystem.create_walk_in(
          space.id,
          multi_start,
          multi_end,
          "Multi Day User",
          "multi@example.com",
          nil,
          nil
        )

      # Create a single-day booking on the same date
      single_start = DateTime.new!(date, ~T[10:00:00], "Etc/UTC")
      single_end = DateTime.new!(date, ~T[16:00:00], "Etc/UTC")

      {:ok, _single_booking} =
        BookingSystem.create_walk_in(
          space.id,
          single_start,
          single_end,
          "Single Day User",
          "single@example.com",
          nil,
          nil
        )

      # Both should appear in the query for that date
      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, date)
      assert length(bookings) == 2

      customer_names = Enum.map(bookings, & &1.customer_name)
      assert "Multi Day User" in customer_names
      assert "Single Day User" in customer_names
    end

    test "slot booking counts correctly include multi-day bookings", %{space: space} do
      date = Date.add(Date.utc_today(), 1)

      # Create a multi-day booking that includes this date
      multi_start = DateTime.new!(Date.add(date, -1), ~T[09:00:00], "Etc/UTC")
      multi_end = DateTime.new!(Date.add(date, 1), ~T[18:00:00], "Etc/UTC")

      {:ok, _multi_booking} =
        BookingSystem.create_walk_in(
          space.id,
          multi_start,
          multi_end,
          "Multi Day User",
          "multi@example.com",
          nil,
          nil
        )

      # Create a single-day booking on the same date
      single_start = DateTime.new!(date, ~T[10:00:00], "Etc/UTC")
      single_end = DateTime.new!(date, ~T[16:00:00], "Etc/UTC")

      {:ok, _single_booking} =
        BookingSystem.create_walk_in(
          space.id,
          single_start,
          single_end,
          "Single Day User",
          "single@example.com",
          nil,
          nil
        )

      # Get slot counts for a time range on that date
      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, date, ~T[11:00:00], ~T[15:00:00])

      # Should count both bookings
      assert counts.approved == 2
      assert counts.pending == 0
    end

    test "multi-day booking with different start and end times", %{space: space} do
      start_date = Date.add(Date.utc_today(), 1)
      end_date = Date.add(Date.utc_today(), 5)

      # Booking starts at 2 PM on day 1 and ends at 11 AM on day 5
      start_datetime = DateTime.new!(start_date, ~T[14:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(end_date, ~T[11:00:00], "Etc/UTC")

      {:ok, booking} =
        BookingSystem.create_walk_in(
          space.id,
          start_datetime,
          end_datetime,
          "Extended Stay User",
          "extended@example.com",
          "+1234567890",
          "Long term booking"
        )

      assert booking.start_datetime == start_datetime
      assert booking.end_datetime == end_datetime
      assert booking.customer_phone == "+1234567890"
      assert booking.customer_comment == "Long term booking"

      # Verify it appears on all days
      for day_offset <- 0..4 do
        check_date = Date.add(start_date, day_offset)
        {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, check_date)
        assert length(bookings) == 1
        assert hd(bookings).customer_name == "Extended Stay User"
      end
    end

    test "multi-day booking does not appear on days outside its range", %{space: space} do
      start_date = Date.add(Date.utc_today(), 5)
      end_date = Date.add(Date.utc_today(), 7)

      start_datetime = DateTime.new!(start_date, ~T[09:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(end_date, ~T[18:00:00], "Etc/UTC")

      {:ok, _booking} =
        BookingSystem.create_walk_in(
          space.id,
          start_datetime,
          end_datetime,
          "Range Test User",
          "range@example.com",
          nil,
          nil
        )

      # Should not appear on day before start
      day_before = Date.add(start_date, -1)

      {:ok, bookings_before} =
        BookingSystem.list_accepted_space_bookings_by_date(space.id, day_before)

      assert length(bookings_before) == 0

      # Should appear on start date
      {:ok, bookings_start} =
        BookingSystem.list_accepted_space_bookings_by_date(space.id, start_date)

      assert length(bookings_start) == 1

      # Should appear on end date
      {:ok, bookings_end} = BookingSystem.list_accepted_space_bookings_by_date(space.id, end_date)
      assert length(bookings_end) == 1

      # Should not appear on day after end
      day_after = Date.add(end_date, 1)

      {:ok, bookings_after} =
        BookingSystem.list_accepted_space_bookings_by_date(space.id, day_after)

      assert length(bookings_after) == 0
    end

    test "very long multi-day booking (30 days)", %{space: space} do
      start_date = Date.add(Date.utc_today(), 1)
      end_date = Date.add(Date.utc_today(), 30)

      start_datetime = DateTime.new!(start_date, ~T[09:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(end_date, ~T[18:00:00], "Etc/UTC")

      {:ok, booking} =
        BookingSystem.create_walk_in(
          space.id,
          start_datetime,
          end_datetime,
          "Long Term User",
          "longterm@example.com",
          nil,
          "Monthly booking"
        )

      assert booking.start_datetime == start_datetime
      assert booking.end_datetime == end_datetime

      # Spot check a few days
      for day_offset <- [0, 10, 20, 29] do
        check_date = Date.add(start_date, day_offset)
        {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, check_date)
        assert length(bookings) == 1
      end

      # Verify it doesn't appear the day after
      day_after = Date.add(end_date, 1)

      {:ok, bookings_after} =
        BookingSystem.list_accepted_space_bookings_by_date(space.id, day_after)

      assert length(bookings_after) == 0
    end
  end

  describe "datetime range overlaps" do
    test "detects overlap when new booking starts during existing booking", %{space: space} do
      # Existing booking: Day 1-3
      day1 = Date.add(Date.utc_today(), 1)
      day2 = Date.add(Date.utc_today(), 2)
      day3 = Date.add(Date.utc_today(), 3)

      existing_start = DateTime.new!(day1, ~T[09:00:00], "Etc/UTC")
      existing_end = DateTime.new!(day3, ~T[18:00:00], "Etc/UTC")

      {:ok, _existing} =
        BookingSystem.create_walk_in(
          space.id,
          existing_start,
          existing_end,
          "Existing User",
          "existing@example.com",
          nil,
          nil
        )

      # Check overlap on day 2
      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, day2, ~T[10:00:00], ~T[16:00:00])

      assert counts.approved == 1
    end

    test "detects overlap when new booking ends during existing booking", %{space: space} do
      # Existing booking: Day 3-5
      day3 = Date.add(Date.utc_today(), 3)
      day4 = Date.add(Date.utc_today(), 4)
      day5 = Date.add(Date.utc_today(), 5)

      existing_start = DateTime.new!(day3, ~T[09:00:00], "Etc/UTC")
      existing_end = DateTime.new!(day5, ~T[18:00:00], "Etc/UTC")

      {:ok, _existing} =
        BookingSystem.create_walk_in(
          space.id,
          existing_start,
          existing_end,
          "Existing User",
          "existing@example.com",
          nil,
          nil
        )

      # Check availability on day 4
      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, day4, ~T[10:00:00], ~T[16:00:00])

      assert counts.approved == 1
    end

    test "detects overlap when new booking completely contains existing booking", %{space: space} do
      # Existing booking: Day 3-5
      day3 = Date.add(Date.utc_today(), 3)
      day4 = Date.add(Date.utc_today(), 4)
      day5 = Date.add(Date.utc_today(), 5)

      existing_start = DateTime.new!(day3, ~T[09:00:00], "Etc/UTC")
      existing_end = DateTime.new!(day5, ~T[18:00:00], "Etc/UTC")

      {:ok, _existing} =
        BookingSystem.create_walk_in(
          space.id,
          existing_start,
          existing_end,
          "Existing User",
          "existing@example.com",
          nil,
          nil
        )

      # Check if overlaps on day 4 (middle day)
      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, day4, ~T[10:00:00], ~T[16:00:00])

      assert counts.approved == 1
    end

    test "detects overlap when new booking is contained within existing booking", %{space: space} do
      # Existing booking: Day 1-10
      day1 = Date.add(Date.utc_today(), 1)
      day5 = Date.add(Date.utc_today(), 5)
      day10 = Date.add(Date.utc_today(), 10)

      existing_start = DateTime.new!(day1, ~T[09:00:00], "Etc/UTC")
      existing_end = DateTime.new!(day10, ~T[18:00:00], "Etc/UTC")

      {:ok, _existing} =
        BookingSystem.create_walk_in(
          space.id,
          existing_start,
          existing_end,
          "Existing User",
          "existing@example.com",
          nil,
          nil
        )

      # Check availability on day 5 (middle day within long booking)
      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, day5, ~T[10:00:00], ~T[16:00:00])

      assert counts.approved == 1
    end

    test "no overlap when bookings are on consecutive days with no time overlap", %{space: space} do
      # First booking: Day 1-2, ending at 12 PM on day 2
      day1 = Date.add(Date.utc_today(), 1)
      day2 = Date.add(Date.utc_today(), 2)

      first_start = DateTime.new!(day1, ~T[09:00:00], "Etc/UTC")
      first_end = DateTime.new!(day2, ~T[12:00:00], "Etc/UTC")

      {:ok, _first} =
        BookingSystem.create_walk_in(
          space.id,
          first_start,
          first_end,
          "First User",
          "first@example.com",
          nil,
          nil
        )

      # Check availability on day 2 afternoon (after first booking ends)
      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, day2, ~T[13:00:00], ~T[18:00:00])

      assert counts.approved == 0
    end
  end
end
