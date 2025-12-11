defmodule SpazioSolazzoWeb.BookingComponents.BookingFormComponent do
  use SpazioSolazzoWeb, :live_component

  def update(assigns, socket) do
    form = assigns[:form] || to_form(%{"customer_name" => "", "customer_email" => ""})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)}
  end

  def handle_event("validate_form", %{"customer_name" => name, "customer_email" => email}, socket) do
    form_data = %{"customer_name" => name, "customer_email" => email}
    {:noreply, assign(socket, form: to_form(form_data))}
  end

  def handle_event("submit_booking", _params, socket) do
    form_data = socket.assigns.form.source

    case validate_booking_form(form_data) do
      :ok ->
        send(self(), {:booking_form_validated, form_data})
        {:noreply, socket}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
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

  def render(assigns) do
    ~H"""
    <div>
      <.modal :if={@show} id={@id} show on_cancel={@on_cancel}>
        <:title>Complete Your Booking</:title>
        <:subtitle>
          <%= if @selected_time_slot do %>
            {@asset.name} - {@selected_time_slot.name} on {Calendar.strftime(
              @selected_date,
              "%B %d, %Y"
            )}
          <% end %>
        </:subtitle>

        <div>
          <.form
            for={@form}
            id="booking-form"
            phx-submit="submit_booking"
            phx-change="validate_form"
            phx-target={@myself}
          >
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
                phx-click={@on_cancel}
                class="flex-1 bg-gray-200 hover:bg-gray-300 text-gray-800 font-semibold py-2 px-4 rounded-lg transition-colors"
              >
                Cancel
              </button>
            </div>
          </.form>
        </div>
      </.modal>
    </div>
    """
  end
end
