defmodule SpazioSolazzo.BookingSystem.DuplicateBookingPreventionTest do
  use SpazioSolazzo.DataCase, async: true

  import SpazioSolazzo.AuthHelpers

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.create_space(
        "Coworking",
        "coworking",
        "Coworking space",
        5
      )

    user = register_user("user@example.com", "Test User")

    %{space: space, user: user}
  end

  describe "duplicate booking prevention" do
    test "prevents user from requesting duplicate booking when they have a pending request", %{
      space: space,
      user: user
    } do
      tomorrow = Date.add(Date.utc_today(), 1)
      start_time = ~T[10:00:00]
      end_time = ~T[12:00:00]

      {:ok, _first_booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      result =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      assert {:error, %Ash.Error.Invalid{}} = result

      assert_error_contains(
        result,
        "You already have a pending or confirmed booking for this time slot"
      )
    end

    test "prevents user from requesting duplicate booking when they have an accepted booking", %{
      space: space,
      user: user
    } do
      tomorrow = Date.add(Date.utc_today(), 1)
      start_time = ~T[10:00:00]
      end_time = ~T[12:00:00]

      {:ok, first_booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      {:ok, _approved} = BookingSystem.approve_booking(first_booking)

      result =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      assert {:error, %Ash.Error.Invalid{}} = result

      assert_error_contains(
        result,
        "You already have a pending or confirmed booking for this time slot"
      )
    end

    test "allows user to request booking after previous booking was rejected", %{
      space: space,
      user: user
    } do
      tomorrow = Date.add(Date.utc_today(), 1)
      start_time = ~T[10:00:00]
      end_time = ~T[12:00:00]

      {:ok, first_booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      {:ok, _rejected} = BookingSystem.reject_booking(first_booking, "Sorry, fully booked")

      {:ok, second_booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      assert second_booking.state == :requested
      assert second_booking.user_id == user.id
    end

    test "allows user to request booking after previous booking was cancelled", %{
      space: space,
      user: user
    } do
      tomorrow = Date.add(Date.utc_today(), 1)
      start_time = ~T[10:00:00]
      end_time = ~T[12:00:00]

      {:ok, first_booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      {:ok, _cancelled} = BookingSystem.cancel_booking(first_booking, "Changed plans")

      {:ok, second_booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      assert second_booking.state == :requested
      assert second_booking.user_id == user.id
    end

    test "prevents overlapping bookings for same user", %{space: space, user: user} do
      tomorrow = Date.add(Date.utc_today(), 1)

      {:ok, _first_booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          ~T[10:00:00],
          ~T[12:00:00],
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      result =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          ~T[11:00:00],
          ~T[13:00:00],
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      assert {:error, %Ash.Error.Invalid{}} = result

      assert_error_contains(
        result,
        "You already have a pending or confirmed booking for this time slot"
      )
    end

    test "allows different users to book the same time slot", %{space: space, user: user} do
      another_user = register_user("another@example.com", "Another User")
      tomorrow = Date.add(Date.utc_today(), 1)
      start_time = ~T[10:00:00]
      end_time = ~T[12:00:00]

      {:ok, _first_booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          start_time,
          end_time,
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      {:ok, second_booking} =
        BookingSystem.create_booking(
          space.id,
          another_user.id,
          tomorrow,
          start_time,
          end_time,
          "Another User",
          "another@example.com",
          nil,
          nil
        )

      assert second_booking.state == :requested
      assert second_booking.user_id == another_user.id
    end

    test "allows user to book different time slots on same day", %{space: space, user: user} do
      tomorrow = Date.add(Date.utc_today(), 1)

      {:ok, _morning_booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          ~T[09:00:00],
          ~T[11:00:00],
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      {:ok, afternoon_booking} =
        BookingSystem.create_booking(
          space.id,
          user.id,
          tomorrow,
          ~T[14:00:00],
          ~T[16:00:00],
          "Test User",
          "user@example.com",
          nil,
          nil
        )

      assert afternoon_booking.state == :requested
      assert afternoon_booking.user_id == user.id
    end

    test "allows guest bookings without user_id validation", %{space: space} do
      tomorrow = Date.add(Date.utc_today(), 1)
      start_time = ~T[10:00:00]
      end_time = ~T[12:00:00]

      {:ok, _first_booking} =
        BookingSystem.create_booking(
          space.id,
          nil,
          tomorrow,
          start_time,
          end_time,
          "Guest User",
          "guest@example.com",
          nil,
          nil
        )

      {:ok, second_booking} =
        BookingSystem.create_booking(
          space.id,
          nil,
          tomorrow,
          start_time,
          end_time,
          "Another Guest",
          "another.guest@example.com",
          nil,
          nil
        )

      assert second_booking.state == :requested
      assert second_booking.user_id == nil
    end
  end

  defp assert_error_contains({:error, %Ash.Error.Invalid{errors: errors}}, expected_message) do
    error_messages =
      Enum.map(errors, fn error ->
        case error do
          %{message: message} -> message
          _ -> inspect(error)
        end
      end)

    assert Enum.any?(error_messages, &String.contains?(&1, expected_message)),
           "Expected error message to contain '#{expected_message}', but got: #{inspect(error_messages)}"
  end
end
