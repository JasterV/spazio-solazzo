defmodule SpazioSolazzo.BookingSystem.BookingTest do
  use ExUnit.Case, async: true
  use SpazioSolazzo.DataCase

  import SpazioSolazzo.AuthHelpers

  alias SpazioSolazzo.BookingSystem

  # Helper for creating booking requests
  defp request_booking(
         space_id,
         user_id,
         date,
         start_time,
         end_time,
         customer_name,
         customer_email,
         customer_phone,
         customer_comment
       ) do
    BookingSystem.create_booking(
      space_id,
      user_id,
      date,
      start_time,
      end_time,
      customer_name,
      customer_email,
      customer_phone,
      customer_comment
    )
  end

  setup do
    {:ok, space} =
      BookingSystem.create_space(
        "Test Space",
        "test-space",
        "Test description",
        2
      )

    user = register_user("testuser@example.com", "Test User")

    date = ~D[2026-02-10]

    %{space: space, user: user, date: date}
  end

  describe "create_booking" do
    test "creates a booking request successfully", %{space: space, date: date} do
      assert {:ok, booking} =
               request_booking(
                 space.id,
                 nil,
                 date,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 "John Doe",
                 "john@example.com",
                 "+39 1234567890",
                 "Test booking"
               )

      assert booking.space_id == space.id
      assert booking.user_id == nil
      assert booking.date == date
      assert booking.start_time == ~T[09:00:00]
      assert booking.end_time == ~T[10:00:00]
      assert booking.customer_name == "John Doe"
      assert booking.customer_email == "john@example.com"
      assert booking.customer_phone == "+39 1234567890"
      assert booking.customer_comment == "Test booking"
      assert booking.state == :requested
    end

    test "creates booking with authenticated user", %{space: space, user: user, date: date} do
      assert {:ok, booking} =
               request_booking(
                 space.id,
                 user.id,
                 date,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 "John Doe",
                 user.email,
                 "+39 1234567890",
                 ""
               )

      assert booking.user_id == user.id
      assert to_string(booking.customer_email) == to_string(user.email)
    end

    test "rejects booking with end time before start time", %{space: space, date: date} do
      assert {:error, error} =
               request_booking(
                 space.id,
                 nil,
                 date,
                 ~T[10:00:00],
                 ~T[09:00:00],
                 "John Doe",
                 "john@example.com",
                 nil,
                 nil
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "must be after start time")
    end

    test "rejects booking in the past", %{space: space} do
      past_date = Date.add(Date.utc_today(), -1)

      assert {:error, error} =
               request_booking(
                 space.id,
                 nil,
                 past_date,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 "John Doe",
                 "john@example.com",
                 nil,
                 nil
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "cannot be in the past")
    end

    test "allows booking for today", %{space: space} do
      today = Date.utc_today()

      assert {:ok, booking} =
               request_booking(
                 space.id,
                 nil,
                 today,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 "John Doe",
                 "john@example.com",
                 nil,
                 nil
               )

      assert booking.date == today
    end

    test "requires customer name and email", %{space: space, date: date} do
      assert {:error, _error} =
               request_booking(
                 space.id,
                 nil,
                 date,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 "",
                 "",
                 "",
                 ""
               )
    end

    test "phone number is optional", %{space: space, date: date} do
      assert {:ok, booking} =
               request_booking(
                 space.id,
                 nil,
                 date,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 "John Doe",
                 "john@example.com",
                 nil,
                 nil
               )

      assert booking.customer_phone == nil || booking.customer_phone == ""
    end
  end

  describe "approve_booking/1" do
    test "approves a pending booking", %{space: space, date: date} do
      {:ok, booking} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "John Doe",
          "john@example.com",
          nil,
          nil
        )

      assert booking.state == :requested

      {:ok, approved_booking} = BookingSystem.approve_booking(booking.id)

      assert approved_booking.state == :accepted
      assert approved_booking.id == booking.id
    end

    test "cannot approve already approved booking", %{space: space, date: date} do
      {:ok, booking} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "John Doe",
          "john@example.com",
          nil,
          nil
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)

      assert {:error, error} = BookingSystem.approve_booking(booking.id)
      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "no matching transition")
    end

    test "cannot approve cancelled booking", %{space: space, date: date} do
      {:ok, booking} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "John Doe",
          "john@example.com",
          nil,
          nil
        )

      {:ok, _} = BookingSystem.cancel_booking(booking.id, "Test cancellation")

      assert {:error, error} = BookingSystem.approve_booking(booking.id)
      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "no matching transition")
    end
  end

  describe "cancel_booking/1" do
    test "cancels a pending booking", %{space: space, date: date} do
      {:ok, booking} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "John Doe",
          "john@example.com",
          nil,
          nil
        )

      {:ok, cancelled_booking} = BookingSystem.cancel_booking(booking.id, "Test cancellation")

      assert cancelled_booking.state == :cancelled
      assert cancelled_booking.id == booking.id
    end

    test "cancels an approved booking", %{space: space, date: date} do
      {:ok, booking} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "John Doe",
          "john@example.com",
          nil,
          nil
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)
      {:ok, cancelled_booking} = BookingSystem.cancel_booking(booking.id, "Test cancellation")

      assert cancelled_booking.state == :cancelled
    end

    test "cannot cancel already cancelled booking", %{space: space, date: date} do
      {:ok, booking} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "John Doe",
          "john@example.com",
          nil,
          nil
        )

      {:ok, _} = BookingSystem.cancel_booking(booking.id, "Test cancellation")

      assert {:error, error} = BookingSystem.cancel_booking(booking.id, "Test cancellation")
      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "no matching transition")
    end
  end

  describe "list_accepted_space_bookings_by_date/2" do
    test "returns only approved bookings for specific date", %{space: space, date: date} do
      {:ok, approved1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(approved1.id)

      {:ok, approved2} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[10:00:00],
          ~T[11:00:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(approved2.id)

      {:ok, _pending} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[11:00:00],
          ~T[12:00:00],
          "User 3",
          "user3@example.com",
          "",
          ""
        )

      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, date)

      assert length(bookings) == 2
      assert Enum.all?(bookings, &(&1.state == :accepted))
    end

    test "does not return cancelled bookings", %{space: space, date: date} do
      {:ok, booking} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)
      {:ok, _} = BookingSystem.cancel_booking(booking.id, "Test cancellation")

      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, date)

      assert bookings == []
    end

    test "only returns bookings for specified date", %{space: space, date: date} do
      other_date = Date.add(date, 1)

      {:ok, booking1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(booking1.id)

      {:ok, booking2} =
        request_booking(
          space.id,
          nil,
          other_date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(booking2.id)

      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, date)

      assert length(bookings) == 1
      assert hd(bookings).date == date
    end

    test "only returns bookings for specified space", %{space: space, date: date} do
      {:ok, other_space} =
        BookingSystem.create_space(
          "Other Space",
          "other-space",
          "Other description",
          5
        )

      {:ok, booking} =
        request_booking(
          other_space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)

      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, date)

      assert bookings == []
    end
  end

  describe "list_booking_requests/3" do
    test "returns pending and approved bookings for space", %{space: space, date: date} do
      {:ok, pending} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, approved} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[10:00:00],
          ~T[11:00:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(approved.id)

      {:ok, cancelled} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[11:00:00],
          ~T[12:00:00],
          "User 3",
          "user3@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.cancel_booking(cancelled.id, "Test cancellation")

      {:ok, bookings} = BookingSystem.list_booking_requests(space.id, nil, nil)

      assert length(bookings) == 2
      assert Enum.any?(bookings, &(&1.id == pending.id))
      assert Enum.any?(bookings, &(&1.id == approved.id))
      refute Enum.any?(bookings, &(&1.id == cancelled.id))
    end

    test "filters by email", %{space: space, date: date} do
      {:ok, _booking1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, booking2} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[10:00:00],
          ~T[11:00:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, bookings} =
        BookingSystem.list_booking_requests(space.id, "user2@example.com", nil)

      assert length(bookings) == 1
      assert hd(bookings).id == booking2.id
    end

    test "filters by date", %{space: space, date: date} do
      other_date = Date.add(date, 1)

      {:ok, booking1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _booking2} =
        request_booking(
          space.id,
          nil,
          other_date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, bookings} = BookingSystem.list_booking_requests(space.id, nil, date)

      assert length(bookings) == 1
      assert hd(bookings).id == booking1.id
    end
  end

  describe "check_availability/4" do
    test "returns :available when under public capacity", %{space: space, date: date} do
      {:ok, booking} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)

      {:ok, status} =
        BookingSystem.check_availability(
          space.id,
          date,
          ~T[09:00:00],
          ~T[10:00:00]
        )

      assert status == :available
    end

    test "returns :over_capacity when at or over capacity", %{
      space: space,
      date: date
    } do
      for i <- 1..2 do
        {:ok, booking} =
          request_booking(
            space.id,
            nil,
            date,
            ~T[09:00:00],
            ~T[10:00:00],
            "User #{i}",
            "user#{i}@example.com",
            "",
            ""
          )

        {:ok, _} = BookingSystem.approve_booking(booking.id)
      end

      {:ok, status} =
        BookingSystem.check_availability(
          space.id,
          date,
          ~T[09:00:00],
          ~T[10:00:00]
        )

      assert status == :over_capacity
    end

    test "only counts overlapping bookings", %{space: space, date: date} do
      {:ok, booking1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(booking1.id)

      {:ok, booking2} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[10:00:00],
          ~T[11:00:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(booking2.id)

      {:ok, status} =
        BookingSystem.check_availability(
          space.id,
          date,
          ~T[10:00:00],
          ~T[11:00:00]
        )

      assert status == :available
    end

    test "counts partial overlaps", %{space: space, date: date} do
      for i <- 1..2 do
        {:ok, booking} =
          request_booking(
            space.id,
            nil,
            date,
            ~T[09:00:00],
            ~T[11:00:00],
            "User #{i}",
            "user#{i}@example.com",
            "",
            ""
          )

        {:ok, _} = BookingSystem.approve_booking(booking.id)
      end

      {:ok, status} =
        BookingSystem.check_availability(
          space.id,
          date,
          ~T[10:00:00],
          ~T[12:00:00]
        )

      assert status == :over_capacity
    end

    test "does not count pending bookings", %{space: space, date: date} do
      for i <- 1..3 do
        {:ok, _booking} =
          request_booking(
            space.id,
            nil,
            date,
            ~T[09:00:00],
            ~T[10:00:00],
            "User #{i}",
            "user#{i}@example.com",
            "",
            ""
          )
      end

      {:ok, status} =
        BookingSystem.check_availability(
          space.id,
          date,
          ~T[09:00:00],
          ~T[10:00:00]
        )

      assert status == :available
    end

    test "does not count cancelled bookings", %{space: space, date: date} do
      for i <- 1..3 do
        {:ok, booking} =
          request_booking(
            space.id,
            nil,
            date,
            ~T[09:00:00],
            ~T[10:00:00],
            "User #{i}",
            "user#{i}@example.com",
            "",
            ""
          )

        {:ok, _} = BookingSystem.approve_booking(booking.id)
        {:ok, _} = BookingSystem.cancel_booking(booking.id, "Test cancellation")
      end

      {:ok, status} =
        BookingSystem.check_availability(
          space.id,
          date,
          ~T[09:00:00],
          ~T[10:00:00]
        )

      assert status == :available
    end
  end

  describe "count_pending_requests/0" do
    test "returns only pending bookings", %{space: space, date: date} do
      {:ok, _pending1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, approved} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[10:00:00],
          ~T[11:00:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(approved.id)

      {:ok, cancelled} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[11:00:00],
          ~T[12:00:00],
          "User 3",
          "user3@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.cancel_booking(cancelled.id, "Test cancellation")

      {:ok, pending_requests} = BookingSystem.count_pending_requests()

      assert length(pending_requests) == 1
      assert Enum.all?(pending_requests, &(&1.state == :requested))
    end

    test "returns empty list when no pending requests", %{space: space, date: date} do
      {:ok, booking} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)

      {:ok, pending_requests} = BookingSystem.count_pending_requests()

      assert pending_requests == []
    end

    test "counts pending requests across multiple spaces", %{space: space, date: date} do
      {:ok, other_space} =
        BookingSystem.create_space(
          "Other Space",
          "other-space-pending",
          "Other description",
          5
        )

      {:ok, _pending1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _pending2} =
        request_booking(
          other_space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, pending_requests} = BookingSystem.count_pending_requests()

      assert length(pending_requests) == 2
    end
  end

  describe "create_walk_in/7" do
    test "creates a walk-in booking with accepted state", %{space: space} do
      start_datetime = DateTime.utc_now() |> DateTime.add(1, :hour)
      end_datetime = DateTime.add(start_datetime, 2, :hour)

      assert {:ok, booking} =
               BookingSystem.create_walk_in(
                 space.id,
                 start_datetime,
                 end_datetime,
                 "Walk-in Customer",
                 "walkin@example.com",
                 "+39 1234567890",
                 "Walk-in booking"
               )

      assert booking.space_id == space.id
      assert booking.customer_name == "Walk-in Customer"
      assert booking.customer_email == "walkin@example.com"
      assert booking.customer_phone == "+39 1234567890"
      assert booking.customer_comment == "Walk-in booking"
      assert booking.state == :accepted
      assert booking.date == DateTime.to_date(start_datetime)
      # Compare times ignoring microseconds
      expected_start = DateTime.to_time(start_datetime)
      expected_end = DateTime.to_time(end_datetime)

      assert booking.start_time.hour == expected_start.hour
      assert booking.start_time.minute == expected_start.minute
      assert booking.start_time.second == expected_start.second

      assert booking.end_time.hour == expected_end.hour
      assert booking.end_time.minute == expected_end.minute
      assert booking.end_time.second == expected_end.second
    end

    test "creates walk-in without optional fields", %{space: space} do
      start_datetime = DateTime.utc_now() |> DateTime.add(1, :hour)
      end_datetime = DateTime.add(start_datetime, 2, :hour)

      assert {:ok, booking} =
               BookingSystem.create_walk_in(
                 space.id,
                 start_datetime,
                 end_datetime,
                 "Walk-in Customer",
                 "walkin@example.com",
                 nil,
                 nil
               )

      assert booking.customer_phone == nil
      assert booking.customer_comment == nil
      assert booking.state == :accepted
    end

    test "rejects walk-in with end datetime before start datetime", %{space: space} do
      start_datetime = DateTime.utc_now() |> DateTime.add(2, :hour)
      end_datetime = DateTime.add(start_datetime, -1, :hour)

      assert {:error, error} =
               BookingSystem.create_walk_in(
                 space.id,
                 start_datetime,
                 end_datetime,
                 "Walk-in Customer",
                 "walkin@example.com",
                 nil,
                 nil
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "must be after start datetime")
    end

    test "rejects walk-in in the past", %{space: space} do
      start_datetime = DateTime.utc_now() |> DateTime.add(-2, :hour)
      end_datetime = DateTime.add(start_datetime, 1, :hour)

      assert {:error, error} =
               BookingSystem.create_walk_in(
                 space.id,
                 start_datetime,
                 end_datetime,
                 "Walk-in Customer",
                 "walkin@example.com",
                 nil,
                 nil
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "cannot be in the past")
    end

    test "rejects walk-in with invalid email", %{space: space} do
      start_datetime = DateTime.utc_now() |> DateTime.add(1, :hour)
      end_datetime = DateTime.add(start_datetime, 2, :hour)

      assert {:error, error} =
               BookingSystem.create_walk_in(
                 space.id,
                 start_datetime,
                 end_datetime,
                 "Walk-in Customer",
                 "invalid-email",
                 nil,
                 nil
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "must be a valid email")
    end

    test "converts datetime to date and time correctly", %{space: space} do
      date = Date.add(Date.utc_today(), 1)
      start_time = ~T[14:30:00]
      end_time = ~T[16:45:00]

      start_datetime = DateTime.new!(date, start_time, "Etc/UTC")
      end_datetime = DateTime.new!(date, end_time, "Etc/UTC")

      assert {:ok, booking} =
               BookingSystem.create_walk_in(
                 space.id,
                 start_datetime,
                 end_datetime,
                 "Walk-in Customer",
                 "walkin@example.com",
                 nil,
                 nil
               )

      assert booking.date == date
      assert booking.start_time == start_time
      assert booking.end_time == end_time
    end

    test "walk-in bookings are counted in availability check", %{space: space} do
      date = Date.add(Date.utc_today(), 1)
      start_time = ~T[09:00:00]
      end_time = ~T[10:00:00]

      for i <- 1..3 do
        BookingSystem.create_walk_in(
          space.id,
          DateTime.new!(date, start_time, "Etc/UTC"),
          DateTime.new!(date, end_time, "Etc/UTC"),
          "Customer #{i}",
          "customer#{i}@example.com",
          nil,
          nil
        )
      end

      {:ok, status} = BookingSystem.check_availability(space.id, date, start_time, end_time)

      assert status == :over_capacity
    end
  end

  describe "get_slot_booking_counts/4" do
    test "counts pending and approved bookings in time slot", %{space: space, date: date} do
      {:ok, _pending1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, approved1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(approved1.id)

      {:ok, approved2} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 3",
          "user3@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(approved2.id)

      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, date, ~T[09:00:00], ~T[10:00:00])

      assert counts.pending == 1
      assert counts.approved == 2
    end

    test "only counts overlapping bookings", %{space: space, date: date} do
      {:ok, _pending1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[08:00:00],
          ~T[09:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _pending2} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[10:00:00],
          ~T[11:00:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, date, ~T[09:00:00], ~T[10:00:00])

      assert counts.pending == 0
      assert counts.approved == 0
    end

    test "counts partial overlaps", %{space: space, date: date} do
      {:ok, _pending1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[08:30:00],
          ~T[09:30:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, approved1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:30:00],
          ~T[10:30:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.approve_booking(approved1.id)

      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, date, ~T[09:00:00], ~T[10:00:00])

      assert counts.pending == 1
      assert counts.approved == 1
    end

    test "does not count cancelled bookings", %{space: space, date: date} do
      {:ok, cancelled} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.cancel_booking(cancelled.id, "Test cancellation")

      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, date, ~T[09:00:00], ~T[10:00:00])

      assert counts.pending == 0
      assert counts.approved == 0
    end

    test "does not count rejected bookings", %{space: space, date: date} do
      {:ok, rejected} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _} = BookingSystem.reject_booking(rejected.id, "Space not available")

      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, date, ~T[09:00:00], ~T[10:00:00])

      assert counts.pending == 0
      assert counts.approved == 0
    end

    test "filters by date correctly", %{space: space, date: date} do
      other_date = Date.add(date, 1)

      {:ok, _pending1} =
        request_booking(
          space.id,
          nil,
          other_date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, date, ~T[09:00:00], ~T[10:00:00])

      assert counts.pending == 0
      assert counts.approved == 0
    end

    test "filters by space correctly", %{space: space, date: date} do
      {:ok, other_space} =
        BookingSystem.create_space(
          "Other Space",
          "other-space-counts",
          "Other description",
          5
        )

      {:ok, _pending1} =
        request_booking(
          other_space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(space.id, date, ~T[09:00:00], ~T[10:00:00])

      assert counts.pending == 0
      assert counts.approved == 0
    end

    test "works with nil space_id to count all spaces", %{space: space, date: date} do
      {:ok, other_space} =
        BookingSystem.create_space(
          "Other Space",
          "other-space-all",
          "Other description",
          5
        )

      {:ok, _pending1} =
        request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 1",
          "user1@example.com",
          "",
          ""
        )

      {:ok, _pending2} =
        request_booking(
          other_space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          "User 2",
          "user2@example.com",
          "",
          ""
        )

      {:ok, counts} =
        BookingSystem.get_slot_booking_counts(nil, date, ~T[09:00:00], ~T[10:00:00])

      assert counts.pending == 2
      assert counts.approved == 0
    end
  end
end
