defmodule SpazioSolazzoWeb.SpaceBookingLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem
  require Ash.Query

  def mount(%{"space_slug" => space_slug}, _session, socket) do
    case BookingSystem.get_space_by_slug(space_slug) do
      {:ok, space} ->
        selected_date = Date.utc_today()

        {:ok, time_slots} =
          BookingSystem.get_space_time_slots_by_date(space.id, selected_date)

        {:ok, bookings} =
          BookingSystem.list_accepted_space_bookings_by_date(space.id, selected_date)

        if connected?(socket) do
          Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
          Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:approved")
          Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:cancelled")
          Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:rejected")
        end

        {:ok,
         socket
         |> assign(
           space: space,
           bookings: bookings,
           selected_date: selected_date,
           selected_time_slot: nil,
           show_booking_modal: false,
           show_success_modal: false,
           time_slots: time_slots,
           current_scope: nil,
           slot_availability: %{},
           slot_booking_counts: %{}
         )
         |> compute_slot_availability()
         |> compute_slot_booking_counts()}

      {:error, _error} ->
        {:ok,
         socket
         |> put_flash(:error, "Space not found")
         |> push_navigate(to: "/")}
    end
  end

  def handle_event("select_slot", %{"time_slot_id" => time_slot_id}, socket) do
    time_slot = Enum.find(socket.assigns.time_slots, &(&1.id == time_slot_id))

    {:noreply,
     assign(socket,
       selected_time_slot: time_slot,
       show_booking_modal: true
     )}
  end

  def handle_event("cancel_booking", _params, socket) do
    {:noreply, assign(socket, show_booking_modal: false)}
  end

  def handle_event("close_success_modal", _params, socket) do
    {:noreply, assign(socket, show_success_modal: false)}
  end

  def handle_info({:create_booking, booking_data}, socket) do
    current_user = socket.assigns.current_user

    result =
      BookingSystem.request_booking(
        socket.assigns.space.id,
        current_user && current_user.id,
        socket.assigns.selected_date,
        socket.assigns.selected_time_slot.start_time,
        socket.assigns.selected_time_slot.end_time,
        %{
          name: booking_data.customer_name,
          email: (current_user && current_user.email) || booking_data.customer_email,
          phone: booking_data.customer_phone,
          comment: booking_data.customer_comment
        }
      )

    case result do
      {:ok, _booking} ->
        {:noreply,
         socket
         |> assign(
           show_booking_modal: false,
           show_success_modal: true
         )}

      {:error, _error} ->
        {:noreply,
         socket
         |> assign(show_booking_modal: false)
         |> put_flash(:error, "Failed to create booking request.")}
    end
  end

  def handle_info({:date_selected, date}, socket) do
    {:ok, time_slots} =
      BookingSystem.get_space_time_slots_by_date(socket.assigns.space.id, date)

    {:ok, bookings} =
      BookingSystem.list_accepted_space_bookings_by_date(socket.assigns.space.id, date)

    {:noreply,
     socket
     |> assign(
       selected_date: date,
       time_slots: time_slots,
       bookings: bookings
     )
     |> compute_slot_availability()
     |> compute_slot_booking_counts()}
  end

  def handle_info(
        %{topic: "booking:" <> _event, payload: %{data: %{space_id: space_id, date: date}}},
        %{assigns: %{space: %{id: space_id}, selected_date: date}} = socket
      ) do
    {:ok, bookings} = BookingSystem.list_accepted_space_bookings_by_date(space_id, date)

    {:noreply,
     socket
     |> assign(bookings: bookings)
     |> compute_slot_availability()
     |> compute_slot_booking_counts()}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp compute_slot_availability(socket) do
    slot_availability =
      socket.assigns.time_slots
      |> Enum.map(fn time_slot ->
        {:ok, status} =
          BookingSystem.check_availability(
            socket.assigns.space.id,
            socket.assigns.selected_date,
            time_slot.start_time,
            time_slot.end_time
          )

        {time_slot.id, status}
      end)
      |> Map.new()

    assign(socket, slot_availability: slot_availability)
  end

  defp compute_slot_booking_counts(socket) do
    slot_booking_counts =
      socket.assigns.time_slots
      |> Enum.map(fn time_slot ->
        {:ok, counts} =
          BookingSystem.get_slot_booking_counts(
            socket.assigns.space.id,
            socket.assigns.selected_date,
            time_slot.start_time,
            time_slot.end_time
          )

        {time_slot.id, counts}
      end)
      |> Map.new()

    assign(socket, slot_booking_counts: slot_booking_counts)
  end
end
