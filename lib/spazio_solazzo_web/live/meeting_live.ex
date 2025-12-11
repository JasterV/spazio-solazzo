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

    {:ok, templates} =
      BookingSystem.TimeSlotTemplate
      |> Ash.Query.filter(space_id == ^space.id)
      |> Ash.read()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
    end

    bookings = load_bookings(asset.id, Date.utc_today())
    form = to_form(%{"customer_name" => "", "customer_email" => ""})

    {:ok,
     socket
     |> assign(
       space: space,
       asset: asset,
       templates: templates,
       selected_date: Date.utc_today(),
       selected_template: nil,
       form: form,
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

  def handle_event("select_slot", %{"template_id" => template_id}, socket) do
    template = Enum.find(socket.assigns.templates, &(&1.id == template_id))

    {:noreply,
     socket
     |> assign(selected_template: template, show_modal: true)}
  end

  def handle_event("validate_form", %{"customer_name" => name, "customer_email" => email}, socket) do
    form_data = %{"customer_name" => name, "customer_email" => email}
    {:noreply, assign(socket, form: to_form(form_data))}
  end

  def handle_event("create_booking", _params, socket) do
    form_data = socket.assigns.form.source

    case validate_booking_form(form_data) do
      :ok ->
        booking_params = %{
          asset_id: socket.assigns.asset.id,
          time_slot_template_id: socket.assigns.selected_template.id,
          date: socket.assigns.selected_date,
          customer_name: form_data["customer_name"],
          customer_email: form_data["customer_email"]
        }

        case create_booking(booking_params) do
          {:ok, _booking} ->
            {:noreply,
             socket
             |> assign(
               show_modal: false,
               show_success_modal: true,
               form: to_form(%{"customer_name" => "", "customer_email" => ""})
             )}

          {:error, error} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to create booking: #{inspect(error)}")}
        end

      {:error, message} ->
        {:noreply,
         socket
         |> put_flash(:error, message)}
    end
  end

  def handle_event("cancel_booking", _params, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end

  def handle_event("close_success_modal", _params, socket) do
    {:noreply, assign(socket, show_success_modal: false)}
  end

  def handle_info(%{topic: "booking:created", payload: %{data: booking}}, socket) do
    if booking.asset_id == socket.assigns.asset.id && booking.date == socket.assigns.selected_date do
      bookings = load_bookings(socket.assigns.asset.id, socket.assigns.selected_date)
      {:noreply, assign(socket, bookings: bookings)}
    else
      {:noreply, socket}
    end
  end

  defp validate_booking_form(%{"customer_name" => name, "customer_email" => email}) do
    cond do
      String.trim(name) == "" ->
        {:error, "Name cannot be empty"}

      not valid_email?(email) ->
        {:error, "Please enter a valid email address"}

      true ->
        :ok
    end
  end

  defp valid_email?(email) do
    email_regex = ~r/^[^\s]+@[^\s]+\.[^\s]+$/
    String.match?(email, email_regex)
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

  defp slot_booked?(template_id, bookings) do
    Enum.any?(bookings, fn booking ->
      booking.time_slot_template_id == template_id
    end)
  end
end
