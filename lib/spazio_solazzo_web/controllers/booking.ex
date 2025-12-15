defmodule SpazioSolazzoWeb.BookingController do
  use SpazioSolazzoWeb, :controller

  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.BookingSystem.Booking.Token

  def handle_action(conn, %{"token" => token, "intent" => intent}) do
    case Token.verify(token) do
      {:ok, %{booking_id: booking_id, role: :admin, scope: _}} when intent == "cancel" ->
        booking = BookingSystem.get_booking_by_id!(booking_id)
        action_result = BookingSystem.cancel_booking(booking)
        build_response(conn, action_result, :cancel)

      {:ok, %{booking_id: booking_id, role: :admin, scope: _}} when intent == "confirm" ->
        booking = BookingSystem.get_booking_by_id!(booking_id)
        action_result = BookingSystem.confirm_booking(booking)
        build_response(conn, action_result, :confirm)

      {:ok, %{booking_id: booking_id, role: :customer, scope: :cancel}} when intent == "cancel" ->
        booking = BookingSystem.get_booking_by_id!(booking_id)
        action_result = BookingSystem.cancel_booking(booking)
        build_response(conn, action_result, :cancel)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid or expired link.")
        |> redirect(to: "/")
    end
  end

  defp build_response(conn, action_result, action_name) do
    case action_result do
      {:ok, _booking} ->
        render(conn, :success, action: action_name)

      {:error, _} ->
        put_flash(conn, :info, "Action could not be completed (e.g. already processed).")
    end
  end
end
