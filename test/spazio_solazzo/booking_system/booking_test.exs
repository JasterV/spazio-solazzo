defmodule SpazioSolazzo.BookingSystem.BookingTest do
  use ExUnit.Case, async: true
  use SpazioSolazzo.DataCase

  import SpazioSolazzo.AuthHelpers

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.create_space(
        "Test Space",
        "test-space",
        "Test description",
        2,
        3
      )

    user = register_user("testuser@example.com", "Test User")

    date = ~D[2026-02-10]

    %{space: space, user: user, date: date}
  end

  describe "request_booking/5" do
    test "creates a booking request successfully", %{space: space, date: date} do
      assert {:ok, booking} =
               BookingSystem.request_booking(
                 space.id,
                 nil,
                 date,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 %{
                   name: "John Doe",
                   email: "john@example.com",
                   phone: "+39 1234567890",
                   comment: "Test booking"
                 }
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
               BookingSystem.request_booking(
                 space.id,
                 user.id,
                 date,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 %{
                   name: "John Doe",
                   email: user.email,
                   phone: "+39 1234567890",
                   comment: ""
                 }
               )

      assert booking.user_id == user.id
      assert to_string(booking.customer_email) == to_string(user.email)
    end

    test "rejects booking with end time before start time", %{space: space, date: date} do
      assert {:error, error} =
               BookingSystem.request_booking(
                 space.id,
                 nil,
                 date,
                 ~T[10:00:00],
                 ~T[09:00:00],
                 %{
                   name: "John Doe",
                   email: "john@example.com",
                   phone: "",
                   comment: ""
                 }
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "must be after start time")
    end

    test "rejects booking in the past", %{space: space} do
      past_date = Date.add(Date.utc_today(), -1)

      assert {:error, error} =
               BookingSystem.request_booking(
                 space.id,
                 nil,
                 past_date,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 %{
                   name: "John Doe",
                   email: "john@example.com",
                   phone: "",
                   comment: ""
                 }
               )

      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "cannot be in the past")
    end

    test "allows booking for today", %{space: space} do
      today = Date.utc_today()

      assert {:ok, booking} =
               BookingSystem.request_booking(
                 space.id,
                 nil,
                 today,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 %{
                   name: "John Doe",
                   email: "john@example.com",
                   phone: "",
                   comment: ""
                 }
               )

      assert booking.date == today
    end

    test "requires customer name and email", %{space: space, date: date} do
      assert {:error, _error} =
               BookingSystem.request_booking(
                 space.id,
                 nil,
                 date,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 %{
                   name: "",
                   email: "",
                   phone: "",
                   comment: ""
                 }
               )
    end

    test "phone number is optional", %{space: space, date: date} do
      assert {:ok, booking} =
               BookingSystem.request_booking(
                 space.id,
                 nil,
                 date,
                 ~T[09:00:00],
                 ~T[10:00:00],
                 %{
                   name: "John Doe",
                   email: "john@example.com",
                   phone: "",
                   comment: ""
                 }
               )

      assert booking.customer_phone == nil || booking.customer_phone == ""
    end
  end

  describe "approve_booking/1" do
    test "approves a pending booking", %{space: space, date: date} do
      {:ok, booking} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{
            name: "John Doe",
            email: "john@example.com",
            phone: "",
            comment: ""
          }
        )

      assert booking.state == :requested

      {:ok, approved_booking} = BookingSystem.approve_booking(booking.id)

      assert approved_booking.state == :accepted
      assert approved_booking.id == booking.id
    end

    test "cannot approve already approved booking", %{space: space, date: date} do
      {:ok, booking} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{
            name: "John Doe",
            email: "john@example.com",
            phone: "",
            comment: ""
          }
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)

      assert {:error, error} = BookingSystem.approve_booking(booking.id)
      error_messages = Ash.Error.error_descriptions(error)
      assert String.contains?(error_messages, "no matching transition")
    end

    test "cannot approve cancelled booking", %{space: space, date: date} do
      {:ok, booking} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{
            name: "John Doe",
            email: "john@example.com",
            phone: "",
            comment: ""
          }
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
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{
            name: "John Doe",
            email: "john@example.com",
            phone: "",
            comment: ""
          }
        )

      {:ok, cancelled_booking} = BookingSystem.cancel_booking(booking.id, "Test cancellation")

      assert cancelled_booking.state == :cancelled
      assert cancelled_booking.id == booking.id
    end

    test "cancels an approved booking", %{space: space, date: date} do
      {:ok, booking} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{
            name: "John Doe",
            email: "john@example.com",
            phone: "",
            comment: ""
          }
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)
      {:ok, cancelled_booking} = BookingSystem.cancel_booking(booking.id, "Test cancellation")

      assert cancelled_booking.state == :cancelled
    end

    test "cannot cancel already cancelled booking", %{space: space, date: date} do
      {:ok, booking} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{
            name: "John Doe",
            email: "john@example.com",
            phone: "",
            comment: ""
          }
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
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(approved1.id)

      {:ok, approved2} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[10:00:00],
          ~T[11:00:00],
          %{name: "User 2", email: "user2@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(approved2.id)

      {:ok, _pending} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[11:00:00],
          ~T[12:00:00],
          %{name: "User 3", email: "user3@example.com", phone: "", comment: ""}
        )

      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, date)

      assert length(bookings) == 2
      assert Enum.all?(bookings, &(&1.state == :accepted))
    end

    test "does not return cancelled bookings", %{space: space, date: date} do
      {:ok, booking} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)
      {:ok, _} = BookingSystem.cancel_booking(booking.id, "Test cancellation")

      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, date)

      assert bookings == []
    end

    test "only returns bookings for specified date", %{space: space, date: date} do
      other_date = Date.add(date, 1)

      {:ok, booking1} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(booking1.id)

      {:ok, booking2} =
        BookingSystem.request_booking(
          space.id,
          nil,
          other_date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 2", email: "user2@example.com", phone: "", comment: ""}
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
          5,
          5
        )

      {:ok, booking} =
        BookingSystem.request_booking(
          other_space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(booking.id)

      {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space.id, date)

      assert bookings == []
    end
  end

  describe "list_booking_requests/3" do
    test "returns pending and approved bookings for space", %{space: space, date: date} do
      {:ok, pending} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
        )

      {:ok, approved} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[10:00:00],
          ~T[11:00:00],
          %{name: "User 2", email: "user2@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(approved.id)

      {:ok, cancelled} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[11:00:00],
          ~T[12:00:00],
          %{name: "User 3", email: "user3@example.com", phone: "", comment: ""}
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
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
        )

      {:ok, booking2} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[10:00:00],
          ~T[11:00:00],
          %{name: "User 2", email: "user2@example.com", phone: "", comment: ""}
        )

      {:ok, bookings} =
        BookingSystem.list_booking_requests(space.id, "user2@example.com", nil)

      assert length(bookings) == 1
      assert hd(bookings).id == booking2.id
    end

    test "filters by date", %{space: space, date: date} do
      other_date = Date.add(date, 1)

      {:ok, booking1} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
        )

      {:ok, _booking2} =
        BookingSystem.request_booking(
          space.id,
          nil,
          other_date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 2", email: "user2@example.com", phone: "", comment: ""}
        )

      {:ok, bookings} = BookingSystem.list_booking_requests(space.id, nil, date)

      assert length(bookings) == 1
      assert hd(bookings).id == booking1.id
    end
  end

  describe "check_availability/4" do
    test "returns :available when under public capacity", %{space: space, date: date} do
      {:ok, booking} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
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

    test "returns :over_public_capacity when at or over public but under real capacity", %{
      space: space,
      date: date
    } do
      for i <- 1..2 do
        {:ok, booking} =
          BookingSystem.request_booking(
            space.id,
            nil,
            date,
            ~T[09:00:00],
            ~T[10:00:00],
            %{name: "User #{i}", email: "user#{i}@example.com", phone: "", comment: ""}
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

      assert status == :over_public_capacity
    end

    test "returns :over_real_capacity when at or over real capacity", %{
      space: space,
      date: date
    } do
      for i <- 1..3 do
        {:ok, booking} =
          BookingSystem.request_booking(
            space.id,
            nil,
            date,
            ~T[09:00:00],
            ~T[10:00:00],
            %{name: "User #{i}", email: "user#{i}@example.com", phone: "", comment: ""}
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

      assert status == :over_real_capacity
    end

    test "only counts overlapping bookings", %{space: space, date: date} do
      {:ok, booking1} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[09:00:00],
          ~T[10:00:00],
          %{name: "User 1", email: "user1@example.com", phone: "", comment: ""}
        )

      {:ok, _} = BookingSystem.approve_booking(booking1.id)

      {:ok, booking2} =
        BookingSystem.request_booking(
          space.id,
          nil,
          date,
          ~T[10:00:00],
          ~T[11:00:00],
          %{name: "User 2", email: "user2@example.com", phone: "", comment: ""}
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
          BookingSystem.request_booking(
            space.id,
            nil,
            date,
            ~T[09:00:00],
            ~T[11:00:00],
            %{name: "User #{i}", email: "user#{i}@example.com", phone: "", comment: ""}
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

      assert status == :over_public_capacity
    end

    test "does not count pending bookings", %{space: space, date: date} do
      for i <- 1..3 do
        {:ok, _booking} =
          BookingSystem.request_booking(
            space.id,
            nil,
            date,
            ~T[09:00:00],
            ~T[10:00:00],
            %{name: "User #{i}", email: "user#{i}@example.com", phone: "", comment: ""}
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
          BookingSystem.request_booking(
            space.id,
            nil,
            date,
            ~T[09:00:00],
            ~T[10:00:00],
            %{name: "User #{i}", email: "user#{i}@example.com", phone: "", comment: ""}
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
end
