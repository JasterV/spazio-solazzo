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
           selected_date: selected_date,
           selected_time_slot: nil,
           show_booking_modal: false,
           show_success_modal: false,
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
    {:noreply, assign(socket, show_booking_modal: false)}
  end

  def handle_event("close_success_modal", _params, socket) do
    {:noreply, assign(socket, show_success_modal: false)}
  end

  def handle_info({:create_booking, comment}, socket) do
    current_user = socket.assigns.current_user

    result =
      BookingSystem.create_booking(
        socket.assigns.selected_time_slot.id,
        socket.assigns.asset.id,
        current_user.id,
        socket.assigns.selected_date,
        current_user.name,
        current_user.email,
        current_user.phone_number,
        comment
      )

    case result do
      {:ok, _booking} ->
        {:noreply,
         socket
         |> assign(
           show_booking_modal: false,
           show_success_modal: true
         )}

      {:error, error} ->
        {:noreply,
         socket
         |> assign(show_booking_modal: false)
         |> put_flash(:error, "Failed to create booking: #{inspect(error)}")}
    end
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

  def handle_info({:date_selected, date}, socket) do
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

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp slot_booked?(time_slot_id, bookings) do
    Enum.any?(bookings, fn booking ->
      booking.time_slot_template_id == time_slot_id
    end)
  end
end
