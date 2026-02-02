defmodule SpazioSolazzoWeb.SpaceBookingLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem
  import SpazioSolazzoWeb.BookingComponents

  def mount(%{"space_slug" => space_slug}, _session, socket) do
    case BookingSystem.get_space_by_slug(space_slug) do
      {:ok, space} ->
        selected_date = Date.utc_today()
        current_user = socket.assigns[:current_user]

        time_slots = load_time_slots_with_stats(space, selected_date, current_user)

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
           selected_date: selected_date,
           selected_time_slot: nil,
           show_booking_modal: false,
           show_success_modal: false,
           time_slots: time_slots
         )}

      {:error, _error} ->
        {:ok,
         socket
         |> put_flash(:error, "Space not found")
         |> push_navigate(to: "/")}
    end
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

  def handle_info({:create_booking, booking_data}, socket) do
    current_user = socket.assigns.current_user

    result =
      BookingSystem.create_booking(
        socket.assigns.space.id,
        current_user.id,
        socket.assigns.selected_date,
        socket.assigns.selected_time_slot.start_time,
        socket.assigns.selected_time_slot.end_time,
        booking_data.customer_name,
        current_user.email,
        booking_data.customer_phone,
        booking_data.customer_comment
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
    time_slots =
      load_time_slots_with_stats(socket.assigns.space, date, socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(
       selected_date: date,
       time_slots: time_slots
     )}
  end

  def handle_info(
        %{topic: "booking:" <> _event, payload: %{data: %{space_id: space_id, date: date}}},
        %{assigns: %{space: %{id: space_id}, selected_date: date}} = socket
      ) do
    time_slots =
      load_time_slots_with_stats(socket.assigns.space, date, socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(time_slots: time_slots)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp load_time_slots_with_stats(space, date, current_user) do
    BookingSystem.get_space_time_slots_by_date!(space.id, date,
      load: [
        booking_stats: %{
          date: date,
          space_id: space.id,
          capacity: space.capacity,
          user_id: current_user.id
        }
      ]
    )
  end
end
