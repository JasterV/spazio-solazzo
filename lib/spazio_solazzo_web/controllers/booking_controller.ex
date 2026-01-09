defmodule SpazioSolazzoWeb.BookingController do
  use SpazioSolazzoWeb, :controller

  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.BookingSystem.Booking
  alias SpazioSolazzo.BookingSystem.Booking.Token

  def confirm(conn, %{"token" => token}) do
    case Token.verify(token) do
      {:ok, %{booking_id: booking_id, role: :admin, action: :confirm}} ->
        case Ash.get(Booking, booking_id, error?: false) do
          {:ok, nil} ->
            conn
            |> put_flash(:error, "Booking not found, cancelling aborted.")
            |> redirect(to: "/")

          {:ok, booking} ->
            action_result = BookingSystem.confirm_booking(booking)
            build_response(conn, action_result, :confirm)

          {:error, _} ->
            conn
            |> put_flash(:error, "Unexpected error occurred, couldn't cancel booking.")
            |> redirect(to: "/")
        end

      _ ->
        conn
        |> put_flash(:error, "Invalid or expired link.")
        |> redirect(to: "/")
    end
  end

  def cancel(conn, %{"token" => token}) do
    case Token.verify(token) do
      {:ok, %{booking_id: booking_id, role: _, action: :cancel}} ->
        case Ash.get(Booking, booking_id, error?: false) do
          {:ok, nil} ->
            conn
            |> put_flash(:error, "Booking not found, cancelling aborted.")
            |> redirect(to: "/")

          {:ok, booking} ->
            action_result = BookingSystem.cancel_booking(booking)
            build_response(conn, action_result, :cancel)

          {:error, _} ->
            conn
            |> put_flash(:error, "Unexpected error occurred, couldn't cancel booking.")
            |> redirect(to: "/")
        end

      _ ->
        conn
        |> put_flash(:error, "Invalid or expired link.")
        |> redirect(to: "/")
    end
  end

  defp build_response(conn, action_result, action_name) do
    case action_result do
      {:ok, _booking} ->
        conn
        |> put_flash(:info, success_message(action_name))
        |> redirect(to: "/")

      {:error, _} ->
        conn
        |> put_flash(:error, "Action could not be completed (e.g. already processed).")
        |> redirect(to: "/")
    end
  end

  defp success_message(:cancel), do: "The booking has been cancelled."
  defp success_message(:confirm), do: "The booking has been confirmed."
  defp success_message(_), do: "Action completed successfully."
end
