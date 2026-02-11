defmodule SpazioSolazzoWeb.BookingFormLiveComponent do
  @moduledoc """
  A live component that collects customer information for completing a booking.
  """

  use SpazioSolazzoWeb, :live_component

  alias SpazioSolazzo.CalendarExt

  def update(assigns, socket) do
    current_user = assigns.current_user

    initial_data = %{
      "customer_name" => current_user.name,
      "customer_phone" => current_user.phone_number || "",
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

  def handle_event("submit_booking", params, socket) do
    booking_data = %{
      customer_name: String.trim(params["customer_name"] || ""),
      customer_phone: String.trim(params["customer_phone"] || ""),
      customer_comment: String.trim(params["customer_comment"] || "")
    }

    send(self(), {:create_booking, booking_data})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal :if={@show} id={@id} show on_cancel={@on_cancel}>
        <:title>Booking request</:title>
        <:subtitle>
          <%= if @selected_time_slot do %>
            {@space.name} | {CalendarExt.format_time_range(@selected_time_slot)} on {CalendarExt.format_date(
              @selected_date
            )}
          <% end %>
        </:subtitle>

        <div>
          <%= if @slot_availability == :over_capacity do %>
            <div class="mb-6 p-4 bg-yellow-50 dark:bg-yellow-900/20 border-l-4 border-yellow-400 rounded">
              <div class="flex gap-3">
                <div class="flex-shrink-0">
                  <.icon
                    name="hero-exclamation-triangle"
                    class="size-5 text-yellow-600 dark:text-yellow-400"
                  />
                </div>
                <div>
                  <p class="text-sm font-semibold text-yellow-800 dark:text-yellow-300">
                    High Demand Time Slot
                  </p>
                  <p class="text-sm text-yellow-700 dark:text-yellow-400 mt-1">
                    This time slot is popular. Your request will be subject to admin approval based on availability.
                  </p>
                </div>
              </div>
            </div>
          <% end %>
          <.form
            for={@form}
            id="booking-form"
            phx-submit="submit_booking"
            phx-change="validate_form"
            phx-target={@myself}
          >
            <div class="mt-6 space-y-4">
              <.input
                name="customer_name"
                id="customer_name"
                label="Name *"
                value={@form[:customer_name].value}
                required
                placeholder="Your full name"
              />

              <div>
                <label class="block text-sm font-medium text-base-content mb-2">
                  Email
                </label>
                <div class="flex items-center gap-3 p-4 bg-secondary/5 rounded-xl border border-base-200">
                  <div class="flex-shrink-0">
                    <.icon name="hero-envelope" class="size-5 text-secondary" />
                  </div>
                  <span class="text-sm font-medium text-base-content truncate">
                    {@current_user.email}
                  </span>
                </div>
              </div>

              <.input
                name="customer_phone"
                id="customer_phone"
                label="Phone (Optional)"
                value={@form[:customer_phone].value}
                placeholder="+39 123456789"
              />

              <.input
                type="textarea"
                name="customer_comment"
                label="Comments (Optional)"
                id="customer_comment"
                placeholder="Any special requests or notes..."
                value={@form[:customer_comment].value}
                rows="4"
              />
            </div>

            <div class="mt-6 p-4 bg-info/5 border border-info/20 rounded-xl">
              <div class="flex gap-3">
                <div class="flex-shrink-0">
                  <.icon name="hero-information-circle" class="size-5 text-info" />
                </div>
                <div class="text-xs text-neutral space-y-1">
                  <ul class="list-disc list-inside space-y-0.5 ml-1">
                    <li>Pricing details will be sent to your email</li>
                    <li>Payment via cash or POS on arrival</li>
                    <li>Cancel anytime with no commitment</li>
                  </ul>
                </div>
              </div>
            </div>

            <%= if @space.slug == "arcipelago" do %>
              <div class="mt-4 p-4 bg-warning/5 border border-warning/20 rounded-xl">
                <div class="flex gap-3">
                  <div class="flex-shrink-0">
                    <.icon name="hero-user-group" class="size-5 text-warning" />
                  </div>
                  <div class="text-xs text-neutral space-y-1">
                    <p class="font-semibold">Membership Required</p>
                    <p>
                      Coworking is for Caravanserai association members. Membership costs €3, can be done at the space, and is valid until December 31, 2026.
                    </p>
                  </div>
                </div>
              </div>
            <% end %>

            <div class="mt-6 flex items-center gap-3">
              <button
                type="submit"
                class="btn btn-secondary flex-1 rounded-2xl"
              >
                Confirm
              </button>
              <button
                type="button"
                phx-click={@on_cancel}
                class="btn btn-ghost btn-primary dark:text-white flex-1 rounded-2xl"
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
