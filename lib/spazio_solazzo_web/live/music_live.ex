defmodule SpazioSolazzoWeb.MusicLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem
  require Ash.Query

  def mount(_params, _session, socket) do
    {:ok, space} =
      BookingSystem.Space
      |> Ash.Query.filter(slug == "music")
      |> Ash.read_one()

    {:ok, asset} =
      BookingSystem.Asset
      |> Ash.Query.filter(space_id == ^space.id)
      |> Ash.read_one()

    {:ok, time_slots} =
      BookingSystem.TimeSlotTemplate
      |> Ash.Query.filter(space_id == ^space.id)
      |> Ash.read()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
    end

    bookings = load_bookings(asset.id, Date.utc_today())

    {:ok,
     socket
     |> assign(
       space: space,
       asset: asset,
       time_slots: time_slots,
       selected_date: Date.utc_today(),
       selected_time_slot: nil,
       show_modal: false,
       show_success_modal: false,
       bookings: bookings
     )}
  end

  def handle_event("change_date", %{"date" => date_string}, socket) do
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        bookings = load_bookings(socket.assigns.asset.id, date)
        {:noreply, assign(socket, selected_date: date, bookings: bookings)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("select_slot", %{"time_slot_id" => time_slot_id}, socket) do
    time_slot = Enum.find(socket.assigns.time_slots, &(&1.id == time_slot_id))

    {:noreply,
     socket
     |> assign(selected_time_slot: time_slot, show_modal: true)}
  end

  def handle_event("cancel_booking", _params, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end

  def handle_event("close_success_modal", _params, socket) do
    {:noreply, assign(socket, show_success_modal: false)}
  end

  def handle_info({:booking_form_validated, form_data}, socket) do
    booking_params = %{
      asset_id: socket.assigns.asset.id,
      time_slot_template_id: socket.assigns.selected_time_slot.id,
      date: socket.assigns.selected_date,
      customer_name: form_data["customer_name"],
      customer_email: form_data["customer_email"]
    }

    case create_booking(booking_params) do
      {:ok, _booking} ->
        {:noreply,
         socket
         |> assign(show_modal: false, show_success_modal: true)}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create booking: #{inspect(error)}")}
    end
  end

  def handle_info(
        %{topic: "booking:created", payload: %{data: %{asset_id: asset_id, date: date}}},
        socket = %{assigns: %{asset: %{id: asset_id}, selected_date: date}}
      ) do
    bookings = load_bookings(asset_id, date)
    {:noreply, assign(socket, bookings: bookings)}
  end

  # Catches all other received booking creation events
  def handle_info(%{topic: "booking:created", payload: _payload}, socket) do
    {:noreply, socket}
  end

  defp create_booking(params) do
    BookingSystem.Booking
    |> Ash.Changeset.for_create(:create, params)
    |> Ash.create()
  end

  defp load_bookings(asset_id, date) do
    case BookingSystem.Booking
         |> Ash.Query.filter(asset_id == ^asset_id and date == ^date)
         |> Ash.read() do
      {:ok, bookings} -> bookings
      {:error, _} -> []
    end
  end

  defp slot_booked?(time_slot_id, bookings) do
    Enum.any?(bookings, fn booking ->
      booking.time_slot_template_id == time_slot_id
    end)
  end
end
