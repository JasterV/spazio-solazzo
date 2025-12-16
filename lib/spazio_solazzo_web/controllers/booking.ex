defmodule SpazioSolazzoWeb.BookingController do
  use SpazioSolazzoWeb, :controller

  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.BookingSystem.Booking
  alias SpazioSolazzo.BookingSystem.Booking.Token

  def confirm(conn, %{"token" => token}) do
    case Token.verify(token) do
      {:ok, %{booking_id: booking_id, role: :admin, action: :confirm}} ->
        booking = Ash.get!(Booking, booking_id)
        action_result = BookingSystem.confirm_booking(booking)
        build_response(conn, action_result, :confirm)

      _ ->
        conn
        |> put_flash(:error, "Invalid or expired link.")
        |> redirect(to: "/")
    end
  end

  def cancel(conn, %{"token" => token}) do
    case Token.verify(token) do
      {:ok, %{booking_id: booking_id, role: _, action: :cancel}} ->
        booking = Ash.get!(Booking, booking_id)
        action_result = BookingSystem.cancel_booking(booking)
        build_response(conn, action_result, :cancel)

      _ ->
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
        conn
        |> put_flash(:info, "Action could not be completed (e.g. already processed).")
        |> redirect(to: "/")
    end
  end
end
