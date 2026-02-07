defmodule SpazioSolazzoWeb.BookingCancellationLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.BookingSystem.Booking.Token

  def mount(%{"token" => token}, _session, socket) do
    case Token.verify(token) do
      {:ok, %{booking_id: booking_id, action: :cancel}} ->
        handle_booking(booking_id, socket)

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Invalid or expired cancellation link")
         |> push_navigate(to: "/")}
    end
  end

  defp handle_booking(booking_id, socket) do
    case Ash.get(SpazioSolazzo.BookingSystem.Booking, booking_id, load: [:space]) do
      {:ok, %{state: state} = booking} when state in [:requested, :accepted] ->
        {:ok,
         assign(socket,
           booking: booking,
           cancellation_reason: "",
           show_success: false
         )}

      {:ok, _} ->
        {:ok,
         socket
         |> put_flash(:error, "This booking has already been cancelled or completed")
         |> push_navigate(to: "/")}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Booking not found")
         |> push_navigate(to: "/")}
    end
  end

  def handle_event("validate", %{"reason" => reason}, socket) do
    {:noreply, assign(socket, cancellation_reason: reason)}
  end

  def handle_event("cancel_booking", %{"reason" => reason}, socket) do
    if String.trim(reason) == "" do
      {:noreply, put_flash(socket, :error, "Please provide a reason for cancellation")}
    else
      booking = socket.assigns.booking

      case BookingSystem.cancel_booking(booking, reason) do
        {:ok, _cancelled_booking} ->
          {:noreply, assign(socket, show_success: true)}

        {:error, _error} ->
          {:noreply, put_flash(socket, :error, "Failed to cancel booking. Please try again.")}
      end
    end
  end
end
