defmodule SpazioSolazzoWeb.BookingControllerTest do
  use SpazioSolazzoWeb.ConnCase, async: true

  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.BookingSystem.Booking.Token

  setup do
    unique_id = :erlang.unique_integer([:positive, :monotonic])

    {:ok, space} =
      BookingSystem.create_space("Test #{unique_id}", "test-space-#{unique_id}", "desc")

    {:ok, asset} = BookingSystem.create_asset("Table 1", space.id)

    {:ok, time_slot} =
      BookingSystem.create_time_slot_template(
        ~T[09:00:00],
        ~T[18:00:00],
        :monday,
        space.id
      )

    user = register_user("test@example.com", "Test User", "+1234567890")

    %{space: space, asset: asset, time_slot: time_slot, user: user}
  end

  describe "cancel/2" do
    test "first cancel shows success message, not error message", %{
      conn: conn,
      asset: asset,
      time_slot: time_slot,
      user: user
    } do
      {:ok, booking} =
        BookingSystem.create_booking(
          time_slot.id,
          asset.id,
          user.id,
          Date.utc_today(),
          "John",
          "john@example.com",
          "+393627384027",
          "test"
        )

      # Verify initial state
      assert booking.state == :reserved

      cancel_token = Token.generate_customer_cancel_token(booking.id)
      conn = get(conn, ~p"/bookings/cancel?token=#{cancel_token}")

      assert redirected_to(conn) == "/"

      # Should show success message
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "The booking has been cancelled."

      # Should NOT show error message
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == nil

      # Verify booking is now cancelled in database
      cancelled_booking = Ash.get!(SpazioSolazzo.BookingSystem.Booking, booking.id)
      assert cancelled_booking.state == :cancelled
    end

    test "shows error message when booking is already cancelled", %{
      conn: conn,
      asset: asset,
      time_slot: time_slot,
      user: user
    } do
      {:ok, booking} =
        BookingSystem.create_booking(
          time_slot.id,
          asset.id,
          user.id,
          Date.utc_today(),
          "John",
          "john@example.com",
          "+393627384027",
          "test"
        )

      # Cancel the booking first time
      {:ok, _cancelled_booking} = BookingSystem.cancel_booking(booking)

      # Generate a cancel token for the already-cancelled booking
      cancel_token = Token.generate_customer_cancel_token(booking.id)

      # Try to cancel again
      conn = get(conn, ~p"/bookings/cancel?token=#{cancel_token}")

      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Action could not be completed (e.g. already processed)."
    end
  end
end
