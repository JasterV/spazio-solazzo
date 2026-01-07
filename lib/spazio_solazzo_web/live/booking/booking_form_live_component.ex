defmodule SpazioSolazzoWeb.BookingFormLiveComponent do
  @moduledoc """
  A live component that collects customer information for completing a booking.
  """

  use SpazioSolazzoWeb, :live_component

  alias SpazioSolazzo.CalendarExt

  @default_phone_prefix "+39"

  def update(assigns, socket) do
    initial_data = %{
      "customer_name" => "",
      "customer_email" => "",
      "phone_prefix" => @default_phone_prefix,
      "phone_number" => "",
      "customer_comment" => ""
    }

    form = assigns[:form] || to_form(initial_data)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)}
  end

  def handle_event("validate_form", params, socket) do
    {:noreply, assign(socket, form: to_form(params))}
  end

  def handle_event("submit_booking", _params, socket) do
    raw_data = socket.assigns.form.source

    case validate_booking_form(raw_data) do
      :ok ->
        # Join prefix and number for the final booking data
        final_phone =
          "#{String.trim(raw_data["phone_prefix"])} #{String.trim(raw_data["phone_number"])}"

        booking_data =
          raw_data
          |> Map.put("customer_phone", final_phone)
          |> Map.drop(["phone_prefix", "phone_number"])

        send(self(), {:booking_form_validated, booking_data})
        {:noreply, socket}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  defp validate_booking_form(data) do
    with :ok <- validate_name(data["customer_name"]),
         :ok <- validate_email(data["customer_email"]),
         :ok <- validate_phone_prefix(data["phone_prefix"]) do
      validate_phone_number(data["phone_number"])
    end
  end

  defp validate_name(name) do
    if String.trim(name || "") == "" do
      {:error, "Name cannot be empty"}
    else
      :ok
    end
  end

  defp validate_email(email) do
    trimmed_email = String.trim(email || "")

    if valid_email?(trimmed_email) do
      :ok
    else
      {:error, "Please enter a valid email address"}
    end
  end

  defp validate_phone_prefix(prefix) do
    trimmed_prefix = String.trim(prefix || "")

    if String.match?(trimmed_prefix, ~r/^\+\d{1,4}$/) do
      :ok
    else
      {:error, "Invalid country code (e.g. +39)"}
    end
  end

  defp validate_phone_number(number) do
    trimmed_number = String.trim(number || "")

    if String.match?(trimmed_number, ~r/^\d{6,15}$/) do
      :ok
    else
      {:error, "Invalid phone number format"}
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
            {@asset.name} | {CalendarExt.format_time_range(@selected_time_slot)} on {CalendarExt.format_date(
              @selected_date
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

              <div class="fieldset mb-2">
                <label>
                  <span class="label mb-1 text-gray-900 dark:text-gray-100">Phone Number</span>
                  <div class="mt-1 flex gap-2 items-center">
                    <div class="w-[3ch] min-w-[55px] flex-shrink-0">
                      <.input
                        field={@form[:phone_prefix]}
                        type="text"
                        placeholder="+39"
                        required
                        maxlength="5"
                        class="w-full input"
                        id="phone_prefix"
                      />
                    </div>
                    <div class="flex-1">
                      <.input
                        field={@form[:phone_number]}
                        type="tel"
                        placeholder="333 1234567"
                        required
                        class="input"
                        id="phone_number"
                      />
                    </div>
                  </div>
                </label>
              </div>

              <.input
                field={@form[:customer_comment]}
                type="textarea"
                label="Additional Comments (Optional)"
                placeholder="Any special requests or notes..."
                rows="3"
              />
            </div>

            <div class="mt-6 flex items-center gap-3">
              <button
                type="submit"
                class="flex-1 bg-teal-600 hover:bg-teal-700 text-white font-semibold py-3 px-4 rounded-2xl transition-colors shadow-lg hover:shadow-xl"
              >
                Book Now
              </button>
              <button
                type="button"
                phx-click={@on_cancel}
                class="flex-1 bg-gray-200 hover:bg-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200 font-semibold py-3 px-4 rounded-2xl transition-colors"
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
