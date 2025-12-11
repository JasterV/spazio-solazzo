defmodule SpazioSolazzoWeb.CoworkingLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem
  require Ash.Query

  def mount(_params, _session, socket) do
    {:ok, space} =
      BookingSystem.Space
      |> Ash.Query.filter(slug == "coworking")
      |> Ash.read_one()

    {:ok, assets} =
      BookingSystem.Asset
      |> Ash.Query.filter(space_id == ^space.id)
      |> Ash.read()

    {:ok, templates} =
      BookingSystem.TimeSlotTemplate
      |> Ash.Query.filter(space_id == ^space.id)
      |> Ash.read()

    form = to_form(%{"customer_name" => "", "customer_email" => ""})

    {:ok,
     socket
     |> assign(
       space: space,
       assets: assets,
       templates: templates,
       selected_asset: nil,
       selected_template: nil,
       selected_date: Date.utc_today(),
       form: form,
       show_modal: false,
       show_success_modal: false,
       bookings: []
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="min-h-screen py-12">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="mb-8">
            <.link navigate="/" class="text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 font-medium">
              ← Back to Home
            </.link>
            <h1 class="text-4xl font-bold text-gray-900 dark:text-white mt-4">{@space.name}</h1>
            <p class="text-gray-600 dark:text-gray-300 mt-2">Select a table and time slot to book</p>

            <div class="mt-6">
              <label for="date-picker" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Select Date
              </label>
              <.form for={%{}} phx-change="change_date">
                <input
                  type="date"
                  id="date-picker"
                  name="date"
                  value={Date.to_string(@selected_date)}
                  min={Date.to_string(Date.utc_today())}
                  class="block w-full max-w-xs px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                />
              </.form>
            </div>
          </div>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <div>
              <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">Available Tables</h2>
              <div class="grid grid-cols-2 gap-4">
                <%= for asset <- @assets do %>
                  <button
                    phx-click="select_asset"
                    phx-value-id={asset.id}
                    class={[
                      "p-6 rounded-lg border-2 transition-all",
                      if(@selected_asset && @selected_asset.id == asset.id,
                        do: "border-indigo-600 dark:border-indigo-500 bg-indigo-50 dark:bg-indigo-900/30",
                        else: "border-gray-200 dark:border-gray-700 hover:border-indigo-300 dark:hover:border-indigo-600 bg-white dark:bg-gray-800"
                      )
                    ]}
                  >
                    <p class="font-semibold text-gray-900 dark:text-white">{asset.name}</p>
                  </button>
                <% end %>
              </div>
            </div>

            <%= if @selected_asset do %>
              <div>
                <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">Time Slots</h2>
                <div class="space-y-3">
                  <%= for template <- @templates do %>
                    <% booked = slot_booked?(template.id, @bookings) %>
                    <button
                      phx-click={unless booked, do: "select_slot"}
                      phx-value-template_id={template.id}
                      disabled={booked}
                      class={[
                        "w-full p-4 rounded-lg border transition-all text-left",
                        if(booked,
                          do: "bg-gray-100 dark:bg-gray-700 border-gray-300 dark:border-gray-600 cursor-not-allowed opacity-75",
                          else:
                            "bg-white dark:bg-gray-800 border-gray-200 dark:border-gray-700 hover:border-indigo-600 dark:hover:border-indigo-500 hover:bg-indigo-50 dark:hover:bg-indigo-900/30 cursor-pointer"
                        )
                      ]}
                    >
                      <div class="flex justify-between items-center">
                        <div>
                          <p class={[
                            "font-semibold",
                            if(booked, do: "text-gray-500 dark:text-gray-400", else: "text-gray-900 dark:text-white")
                          ]}>
                            {template.name}
                          </p>
                          <p class="text-sm text-gray-600 dark:text-gray-300">
                            {Calendar.strftime(template.start_time, "%I:%M %p")} - {Calendar.strftime(
                              template.end_time,
                              "%I:%M %p"
                            )}
                          </p>
                        </div>
                        <%= if booked do %>
                          <span class="px-3 py-1 bg-gray-200 dark:bg-gray-600 text-gray-700 dark:text-gray-300 text-sm font-semibold rounded-full">
                            Booked
                          </span>
                        <% else %>
                          <span class="px-3 py-1 bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 text-sm font-semibold rounded-full">
                            Available
                          </span>
                        <% end %>
                      </div>
                    </button>
                  <% end %>
                </div>
              </div>
            <% else %>
              <div class="flex items-center justify-center">
                <p class="text-gray-500 dark:text-gray-400 text-center">Select a table to view available time slots</p>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <.modal :if={@show_modal} id="booking-modal" show on_cancel={JS.push("cancel_booking")}>
        <:title>Complete Your Booking</:title>
        <:subtitle>
          <%= if @selected_asset && @selected_template do %>
            {@selected_asset.name} - {@selected_template.name} on {Calendar.strftime(
              @selected_date,
              "%B %d, %Y"
            )}
          <% end %>
        </:subtitle>

        <.form for={@form} id="booking-form" phx-submit="create_booking" phx-change="validate_form">
          <div class="mt-6 space-y-4">
            <.input
              field={@form[:customer_name]}
              type="text"
              label="Full Name"
              placeholder="John Doe"
              required
            />
            <.input
              field={@form[:customer_email]}
              type="email"
              label="Email"
              placeholder="john@example.com"
              required
            />
          </div>

          <div class="mt-6 flex items-center gap-3">
            <button
              type="submit"
              class="flex-1 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-4 rounded-lg transition-colors"
            >
              Book Now
            </button>
            <button
              type="button"
              phx-click="cancel_booking"
              class="flex-1 bg-gray-200 hover:bg-gray-300 text-gray-800 font-semibold py-2 px-4 rounded-lg transition-colors"
            >
              Cancel
            </button>
          </div>
        </.form>
      </.modal>

      <.modal
        :if={@show_success_modal}
        id="success-modal"
        show
        on_cancel={JS.push("close_success_modal")}
      >
        <:title>
          <div class="flex items-center gap-3">
            <div class="w-12 h-12 rounded-full bg-green-100 flex items-center justify-center">
              <svg
                class="w-6 h-6 text-green-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                />
              </svg>
            </div>
            <span>Booking Successful!</span>
          </div>
        </:title>

        <div class="mt-6">
          <p class="text-gray-600 text-center mb-6">
            Your booking has been confirmed. You will receive a confirmation email shortly.
          </p>
          <button
            phx-click="close_success_modal"
            class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-4 rounded-lg transition-colors"
          >
            Got it!
          </button>
        </div>
      </.modal>
    </Layouts.app>
    """
  end

  def handle_event("change_date", %{"date" => date_string}, socket) do
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        bookings =
          if socket.assigns.selected_asset do
            load_bookings(socket.assigns.selected_asset.id, date)
          else
            []
          end

        {:noreply, assign(socket, selected_date: date, bookings: bookings)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("select_asset", %{"id" => id}, socket) do
    asset = Enum.find(socket.assigns.assets, &(&1.id == id))

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
    end

    bookings = load_bookings(asset.id, socket.assigns.selected_date)

    {:noreply, assign(socket, selected_asset: asset, bookings: bookings)}
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
          asset_id: socket.assigns.selected_asset.id,
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
    if socket.assigns.selected_asset && booking.asset_id == socket.assigns.selected_asset.id &&
         booking.date == socket.assigns.selected_date do
      bookings = load_bookings(socket.assigns.selected_asset.id, socket.assigns.selected_date)
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
