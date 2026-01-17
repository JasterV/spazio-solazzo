defmodule SpazioSolazzoWeb.BookingFormLiveComponent do
  @moduledoc """
  A live component that collects customer information for completing a booking.
  """

  use SpazioSolazzoWeb, :live_component

  alias SpazioSolazzo.CalendarExt

  def update(assigns, socket) do
    initial_data = %{
      "customer_name" => assigns.current_user.name,
      "customer_phone" => assigns.current_user.phone_number || "",
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
      customer_name: params["customer_name"] || "",
      customer_phone: params["customer_phone"] || "",
      customer_comment: params["customer_comment"] || ""
    }

    send(self(), {:create_booking, booking_data})
    {:noreply, socket}
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
              <div>
                <label
                  for="customer_name"
                  class="block text-sm font-medium text-base-content mb-2"
                >
                  Name <span class="text-error">*</span>
                </label>
                <div class="relative">
                  <input
                    type="text"
                    name="customer_name"
                    id="customer_name"
                    value={@form[:customer_name].value}
                    required
                    class="input input-bordered w-full pl-11 pr-4 py-3 rounded-xl focus:border-secondary !outline-none text-base-content"
                    placeholder="Your full name"
                  />
                  <div class="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none">
                    <.icon name="hero-user" class="size-5 text-base-content/60" />
                  </div>
                </div>
              </div>

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

              <div>
                <label
                  for="customer_phone"
                  class="block text-sm font-medium text-base-content mb-2"
                >
                  Phone (Optional)
                </label>
                <div class="relative">
                  <input
                    type="tel"
                    name="customer_phone"
                    id="customer_phone"
                    value={@form[:customer_phone].value}
                    class="input input-bordered w-full pl-11 pr-4 py-3 rounded-xl focus:border-secondary !outline-none text-base-content"
                    placeholder="+39 123456789"
                  />
                  <div class="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none">
                    <.icon name="hero-phone" class="size-5 text-base-content/60" />
                  </div>
                </div>
              </div>

              <div>
                <label
                  for="customer_comment"
                  class="block text-sm font-medium text-base-content mb-2"
                >
                  Comments (Optional)
                </label>
                <textarea
                  name="customer_comment"
                  id="customer_comment"
                  placeholder="Any special requests or notes..."
                  rows="4"
                  class="textarea textarea-bordered w-full rounded-xl focus:border-secondary resize-none"
                >{@form[:customer_comment].value}</textarea>
              </div>
            </div>

            <div class="mt-6 p-4 bg-info/5 border border-info/20 rounded-xl">
              <div class="flex gap-3">
                <div class="flex-shrink-0">
                  <.icon name="hero-information-circle" class="size-5 text-info" />
                </div>
                <div class="text-xs text-neutral space-y-1">
                  <ul class="list-disc list-inside space-y-0.5 ml-1">
                    <li>Cancel anytime with no commitment</li>
                    <li>Payment upon arrival only</li>
                  </ul>
                </div>
              </div>
            </div>

            <div class="mt-6 flex items-center gap-3">
              <button
                type="submit"
                class="btn btn-primary flex-1 rounded-2xl"
              >
                Confirm
              </button>
              <button
                type="button"
                phx-click={@on_cancel}
                class="btn btn-ghost flex-1 rounded-2xl"
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
