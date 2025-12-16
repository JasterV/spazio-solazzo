defmodule SpazioSolazzoWeb.BookingControllerTest do
  use SpazioSolazzoWeb.ConnCase, async: true

  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.BookingSystem.Booking.Token

  setup do
    {:ok, space} = BookingSystem.create_space("Test", "test-space", "desc")
    {:ok, asset} = BookingSystem.create_asset("Table 1", space.id)

    {:ok, time_slot} =
      BookingSystem.create_time_slot_template(
        "Full Day",
        ~T[09:00:00],
        ~T[18:00:00],
        :monday,
        space.id
      )

    %{space: space, asset: asset, time_slot: time_slot}
  end

  describe "cancel/2" do
    test "returns error response when booking is already cancelled", %{
      conn: conn,
      asset: asset,
      time_slot: time_slot
    } do
      {:ok, booking} =
        BookingSystem.create_booking(
          time_slot.id,
          asset.id,
          Date.utc_today(),
          "John",
          "john@example.com"
        )

      # Cancel the booking first time
      {:ok, _cancelled_booking} = BookingSystem.cancel_booking(booking)

      # Generate a cancel token for the already-cancelled booking
      cancel_token = Token.generate_customer_cancel_token(booking.id)

      # Try to cancel again - this should return a response, not crash
      conn = get(conn, ~p"/bookings/cancel?token=#{cancel_token}")

      # The controller should handle the error gracefully and send a response
      assert conn.state == :sent
      assert conn.status in [200, 302]
    end
  end
end
