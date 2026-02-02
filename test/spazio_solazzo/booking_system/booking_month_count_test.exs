defmodule SpazioSolazzo.BookingSystem.BookingMonthCountTest do
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  describe "list_bookings_for_month_count/3" do
    setup do
      # Create space
      {:ok, space} = BookingSystem.create_space("Coworking", "coworking", "Desc", 10)

      # Use dates in the future (next month, day 15)
      today = Date.utc_today()
      next_month = Date.add(today, 30)
      test_date = %{next_month | day: 15}

      start_datetime = DateTime.new!(test_date, ~T[09:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(test_date, ~T[17:00:00], "Etc/UTC")

      # Create booking with full data
      {:ok, booking} =
        BookingSystem.create_walk_in(
          space.id,
          start_datetime,
          end_datetime,
          "John Doe",
          "john@example.com",
          "555-1234",
          "Test comment"
        )

      # Reload booking
      {:ok, booking} = Ash.reload(booking)

      # Calculate month boundaries
      start_of_month = Date.beginning_of_month(test_date)
      end_of_month = Date.end_of_month(test_date)

      %{
        space: space,
        booking: booking,
        test_date: test_date,
        start_of_month: start_of_month,
        end_of_month: end_of_month
      }
    end

    test "returns only datetime fields, not full booking data",
         %{space: space, start_of_month: start_date, end_of_month: end_date} do
      start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(Date.add(end_date, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          start_datetime,
          end_datetime,
          [:accepted],
          [:start_datetime, :end_datetime]
        )

      assert length(bookings) == 1
      booking = hd(bookings)

      # Assert datetime fields ARE present
      assert %DateTime{} = booking.start_datetime
      assert %DateTime{} = booking.end_datetime

      # Assert other fields are NOT loaded
      refute Ash.Resource.loaded?(booking, :customer_name)
      refute Ash.Resource.loaded?(booking, :customer_email)
      refute Ash.Resource.loaded?(booking, :customer_phone)
      refute Ash.Resource.loaded?(booking, :customer_comment)
      refute Ash.Resource.loaded?(booking, :user)
      refute Ash.Resource.loaded?(booking, :space)
    end

    test "returns empty list for month with no bookings", %{space: space} do
      # Query a different month (two months from now)
      today = Date.utc_today()
      future_month = Date.add(today, 60)
      start_date = Date.beginning_of_month(future_month)
      end_date = Date.end_of_month(future_month)

      start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(Date.add(end_date, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          start_datetime,
          end_datetime,
          [:accepted],
          [:start_datetime, :end_datetime]
        )

      assert bookings == []
    end

    test "handles bookings that span multiple days",
         %{space: space, test_date: test_date, start_of_month: start_date, end_of_month: end_date} do
      # Create a 3-day booking (day 20-22)
      multi_day_start = %{test_date | day: 20}
      multi_day_end = %{test_date | day: 22}

      start_datetime = DateTime.new!(multi_day_start, ~T[09:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(multi_day_end, ~T[17:00:00], "Etc/UTC")

      {:ok, _booking} =
        BookingSystem.create_walk_in(
          space.id,
          start_datetime,
          end_datetime,
          "Jane Doe",
          "jane@example.com",
          nil,
          nil
        )

      month_start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
      month_end_datetime = DateTime.new!(Date.add(end_date, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          month_start_datetime,
          month_end_datetime,
          [:accepted],
          [:start_datetime, :end_datetime]
        )

      # Should have 2 bookings (original + multi-day)
      assert length(bookings) == 2

      # All should only have datetime fields
      Enum.each(bookings, fn booking ->
        refute Ash.Resource.loaded?(booking, :customer_name)
        refute Ash.Resource.loaded?(booking, :customer_email)
      end)
    end

    test "handles month boundaries correctly",
         %{space: space, test_date: test_date, start_of_month: start_date, end_of_month: end_date} do
      # Booking starts before month, ends during month (last day of previous month to day 2)
      before_month = Date.add(start_date, -1)
      during_month = %{test_date | day: 2}

      start_datetime1 = DateTime.new!(before_month, ~T[09:00:00], "Etc/UTC")
      end_datetime1 = DateTime.new!(during_month, ~T[17:00:00], "Etc/UTC")

      {:ok, _before} =
        BookingSystem.create_walk_in(
          space.id,
          start_datetime1,
          end_datetime1,
          "Before Month",
          "before@example.com",
          nil,
          nil
        )

      # Booking starts during month, ends after month (day 27 to first day of next month)
      during_month2 = %{test_date | day: min(27, Date.days_in_month(test_date))}
      after_month = Date.add(end_date, 1)

      start_datetime2 = DateTime.new!(during_month2, ~T[09:00:00], "Etc/UTC")
      end_datetime2 = DateTime.new!(after_month, ~T[17:00:00], "Etc/UTC")

      {:ok, _after} =
        BookingSystem.create_walk_in(
          space.id,
          start_datetime2,
          end_datetime2,
          "After Month",
          "after@example.com",
          nil,
          nil
        )

      month_start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
      month_end_datetime = DateTime.new!(Date.add(end_date, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          month_start_datetime,
          month_end_datetime,
          [:accepted],
          [:start_datetime, :end_datetime]
        )

      # Should include all 3 bookings (original + before + after)
      assert length(bookings) == 3
    end

    test "only returns accepted bookings, not pending/rejected/cancelled",
         %{space: space, test_date: test_date, start_of_month: start_date, end_of_month: end_date} do
      # Create a regular requested booking (not walk-in) on day 10
      pending_date = %{test_date | day: 10}

      {:ok, _pending} =
        BookingSystem.create_booking(
          space.id,
          nil,
          pending_date,
          ~T[09:00:00],
          ~T[17:00:00],
          "Pending",
          "pending@example.com",
          nil,
          nil
        )

      # Create and reject a booking on day 11
      rejected_date = %{test_date | day: 11}

      {:ok, rejected} =
        BookingSystem.create_booking(
          space.id,
          nil,
          rejected_date,
          ~T[09:00:00],
          ~T[17:00:00],
          "Rejected",
          "rejected@example.com",
          nil,
          nil
        )

      {:ok, _} = BookingSystem.reject_booking(rejected, "Test reason")

      month_start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
      month_end_datetime = DateTime.new!(Date.add(end_date, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          month_start_datetime,
          month_end_datetime,
          [:accepted],
          [:start_datetime, :end_datetime]
        )

      # Should only have the original accepted booking from setup
      assert length(bookings) == 1
    end

    test "handles bookings at exact month boundaries",
         %{space: space, start_of_month: start_date, end_of_month: end_date} do
      # Booking exactly at month start
      month_start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
      month_start_end = DateTime.new!(start_date, ~T[08:00:00], "Etc/UTC")

      {:ok, _start} =
        BookingSystem.create_walk_in(
          space.id,
          month_start_datetime,
          month_start_end,
          "Start Boundary",
          "start@example.com",
          nil,
          nil
        )

      # Booking exactly at month end
      month_end_start = DateTime.new!(end_date, ~T[18:00:00], "Etc/UTC")
      month_end_datetime = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")

      {:ok, _end} =
        BookingSystem.create_walk_in(
          space.id,
          month_end_start,
          month_end_datetime,
          "End Boundary",
          "end@example.com",
          nil,
          nil
        )

      month_start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
      month_end_datetime = DateTime.new!(Date.add(end_date, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          month_start_datetime,
          month_end_datetime,
          [:accepted],
          [:start_datetime, :end_datetime]
        )

      # Should include all bookings including boundaries
      assert length(bookings) >= 3
    end

    test "filters by space_id correctly",
         %{space: space, test_date: test_date, start_of_month: start_date, end_of_month: end_date} do
      # Create another space
      {:ok, other_space} = BookingSystem.create_space("Other", "other", "Other space", 5)

      # Create booking for other space on day 16
      other_date = %{test_date | day: 16}
      start_datetime = DateTime.new!(other_date, ~T[09:00:00], "Etc/UTC")
      end_datetime = DateTime.new!(other_date, ~T[17:00:00], "Etc/UTC")

      {:ok, _other_booking} =
        BookingSystem.create_walk_in(
          other_space.id,
          start_datetime,
          end_datetime,
          "Other Space",
          "other@example.com",
          nil,
          nil
        )

      # Query for original space
      month_start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
      month_end_datetime = DateTime.new!(Date.add(end_date, 1), ~T[00:00:00], "Etc/UTC")

      {:ok, bookings} =
        BookingSystem.search_bookings(
          space.id,
          month_start_datetime,
          month_end_datetime,
          [:accepted],
          [:start_datetime, :end_datetime]
        )

      # Should only return bookings for the original space
      assert length(bookings) == 1
    end
  end
end
