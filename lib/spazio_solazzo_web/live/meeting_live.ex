defmodule SpazioSolazzoWeb.MeetingLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem
  require Ash.Query

  def mount(_params, _session, socket) do
    {:ok, space} =
      BookingSystem.Space
      |> Ash.Query.filter(slug == "meeting")
      |> Ash.read_one()

    {:ok, asset} =
      BookingSystem.Asset
      |> Ash.Query.filter(space_id == ^space.id)
      |> Ash.read_one()

    selected_date = Date.utc_today()
    time_slots = load_time_slots_for_date(space.id, selected_date)
    bookings = load_bookings(asset.id, selected_date)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
    end

    {:ok,
     socket
     |> assign(
       space: space,
       asset: asset,
       time_slots: time_slots,
       bookings: bookings,
       selected_date: selected_date,
       selected_time_slot: nil,
       show_booking_modal: false,
       show_verification_modal: false,
       show_verification_expired_modal: false,
       show_success_modal: false,
       email_verification_id: nil,
       pending_booking_data: nil
     )}
  end

  def handle_event("change_date", %{"date" => date_string}, socket) do
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        time_slots = load_time_slots_for_date(socket.assigns.space.id, date)
        bookings = load_bookings(socket.assigns.asset.id, date)

        {:noreply,
         assign(socket,
           selected_date: date,
           time_slots: time_slots,
           bookings: bookings
         )}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("select_slot", %{"time_slot_id" => time_slot_id}, socket) do
    time_slot = Enum.find(socket.assigns.time_slots, &(&1.id == time_slot_id))

    {:noreply,
     socket
     |> assign(selected_time_slot: time_slot, show_booking_modal: true)}
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
      asset_id: socket.assigns.asset.id,
      time_slot_template_id: socket.assigns.selected_time_slot.id,
      date: socket.assigns.selected_date,
      customer_name: form_data["customer_name"],
      customer_email: form_data["customer_email"]
    }

    case BookingSystem.EmailVerification
         |> Ash.Changeset.for_create(:create, %{email: form_data["customer_email"]})
         |> Ash.create() do
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
      BookingSystem.Booking
      |> Ash.Changeset.for_create(:create, assigns.pending_booking_data)
      |> Ash.create()

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
        socket = %{assigns: %{email_verification_id: id}}
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
        socket = %{assigns: %{asset: %{id: asset_id}, selected_date: date}}
      ) do
    bookings = load_bookings(asset_id, date)
    {:noreply, assign(socket, bookings: bookings)}
  end

  # Catches all other received booking creation events
  def handle_info(%{topic: "booking:created", payload: _payload}, socket) do
    {:noreply, socket}
  end

  # Catch-all for any unexpected messages
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp load_time_slots_for_date(space_id, date) do
    day_of_week = day_of_week_atom(date)

    case BookingSystem.TimeSlotTemplate
         |> Ash.Query.filter(space_id == ^space_id and day_of_week == ^day_of_week)
         |> Ash.read() do
      {:ok, slots} -> slots
      {:error, _} -> []
    end
  end

  defp day_of_week_atom(date) do
    case Date.day_of_week(date) do
      1 -> :monday
      2 -> :tuesday
      3 -> :wednesday
      4 -> :thursday
      5 -> :friday
      6 -> :saturday
      7 -> :sunday
    end
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
