defmodule SpazioSolazzoWeb.AssetBookingLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem
  import SpazioSolazzoWeb.BookingComponents
  require Ash.Query

  def mount(%{"asset_id" => asset_id}, _session, socket) do
    case BookingSystem.get_asset_by_id(asset_id, load: [:space]) do
      {:ok, asset} ->
        selected_date = Date.utc_today()

        {:ok, time_slots} =
          BookingSystem.get_space_time_slots_by_date(asset.space.id, selected_date)

        {:ok, bookings} =
          BookingSystem.list_active_asset_bookings_by_date(asset.id, selected_date)

        if connected?(socket) do
          Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
          Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:cancelled")
        end

        {:ok,
         socket
         |> assign(
           asset: asset,
           space: asset.space,
           bookings: bookings,
           email_verification_id: nil,
           pending_booking_data: nil,
           selected_date: selected_date,
           selected_time_slot: nil,
           show_booking_modal: false,
           show_success_modal: false,
           show_verification_expired_modal: false,
           show_verification_modal: false,
           time_slots: time_slots
         )}

      {:error, _error} ->
        {:ok,
         socket
         |> put_flash(:error, "Asset not found")
         |> push_navigate(to: "/")}
    end
  end

  def handle_event("change_date", %{"date" => date_string}, socket) do
    date = Date.from_iso8601!(date_string)

    {:ok, time_slots} =
      BookingSystem.get_space_time_slots_by_date(socket.assigns.space.id, date)

    {:ok, bookings} =
      BookingSystem.list_active_asset_bookings_by_date(socket.assigns.asset.id, date)

    {:noreply,
     assign(socket,
       selected_date: date,
       time_slots: time_slots,
       bookings: bookings
     )}
  end

  def handle_event("select_slot", %{"time_slot_id" => time_slot_id}, socket) do
    time_slot = Enum.find(socket.assigns.time_slots, &(&1.id == time_slot_id))
    {:noreply, assign(socket, selected_time_slot: time_slot, show_booking_modal: true)}
  end

  def handle_event("cancel_booking", _params, socket) do
    {:noreply,
     assign(socket,
       show_booking_modal: false,
       show_verification_modal: false,
       show_verification_expired_modal: false,
       email_verification_id: nil,
       pending_booking_data: nil
     )}
  end

  def handle_event("close_success_modal", _params, socket) do
    {:noreply, assign(socket, show_success_modal: false)}
  end

  def handle_info({:booking_form_validated, form_data}, socket) do
    booking_params = %{
      customer_name: form_data["customer_name"],
      customer_email: form_data["customer_email"],
      customer_phone: form_data["customer_phone"],
      customer_comment: form_data["customer_comment"]
    }

    case BookingSystem.create_verification_code(booking_params.customer_email) do
      {:ok, verification} ->
        Phoenix.PubSub.subscribe(
          SpazioSolazzo.PubSub,
          "email_verification:verification_code_expired:#{verification.id}"
        )

        {:noreply,
         socket
         |> assign(
           show_booking_modal: false,
           show_verification_modal: true,
           email_verification_id: verification.id,
           pending_booking_data: booking_params
         )}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to send verification code: #{inspect(error)}")}
    end
  end

  def handle_info(:email_verified, %{assigns: assigns} = socket) do
    Phoenix.PubSub.unsubscribe(
      SpazioSolazzo.PubSub,
      "email_verification:verification_code_expired:#{assigns.email_verification_id}"
    )

    result =
      BookingSystem.create_booking(
        socket.assigns.selected_time_slot.id,
        socket.assigns.asset.id,
        socket.assigns.selected_date,
        socket.assigns.pending_booking_data.customer_name,
        socket.assigns.pending_booking_data.customer_email,
        socket.assigns.pending_booking_data.customer_phone,
        socket.assigns.pending_booking_data.customer_comment
      )

    case result do
      {:ok, _booking} ->
        {:noreply,
         socket
         |> assign(
           show_verification_modal: false,
           show_success_modal: true,
           email_verification_id: nil,
           pending_booking_data: nil
         )}

      {:error, error} ->
        {:noreply,
         socket
         |> assign(show_verification_modal: false)
         |> put_flash(:error, "Failed to create booking: #{inspect(error)}")}
    end
  end

  def handle_info(
        %{topic: "email_verification:verification_code_expired:" <> id},
        %{assigns: %{email_verification_id: id}} = socket
      ) do
    Phoenix.PubSub.unsubscribe(
      SpazioSolazzo.PubSub,
      "email_verification:verification_code_expired:#{id}"
    )

    {:noreply,
     assign(socket,
       show_verification_modal: false,
       show_verification_expired_modal: true,
       email_verification_id: nil,
       pending_booking_data: nil
     )}
  end

  def handle_info(
        %{topic: "booking:created", payload: %{data: %{asset_id: asset_id, date: date}}},
        %{assigns: %{asset: %{id: asset_id}, selected_date: date}} = socket
      ) do
    {:ok, bookings} = BookingSystem.list_active_asset_bookings_by_date(asset_id, date)
    {:noreply, assign(socket, bookings: bookings)}
  end

  def handle_info(
        %{topic: "booking:cancelled", payload: %{data: %{asset_id: asset_id, date: date}}},
        %{assigns: %{asset: %{id: asset_id}, selected_date: date}} = socket
      ) do
    {:ok, bookings} = BookingSystem.list_active_asset_bookings_by_date(asset_id, date)
    {:noreply, assign(socket, bookings: bookings)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp slot_booked?(time_slot_id, bookings) do
    Enum.any?(bookings, fn booking ->
      booking.time_slot_template_id == time_slot_id
    end)
  end
end
