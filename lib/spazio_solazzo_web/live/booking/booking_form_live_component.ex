defmodule SpazioSolazzoWeb.BookingFormLiveComponent do
  @moduledoc """
  A live component that collects customer information for completing a booking.
  """

  use SpazioSolazzoWeb, :live_component

  alias SpazioSolazzo.CalendarExt

  def update(assigns, socket) do
    initial_data = %{
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
    comment = params["customer_comment"] || ""
    send(self(), {:create_booking, comment})
    {:noreply, socket}
  end

  # TODO: Make name and phone fields editable
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
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                  Name
                </label>
                <div class="flex items-center gap-3 p-4 bg-gradient-to-r from-slate-50 to-sky-50/50 dark:from-slate-900 dark:to-slate-800 rounded-xl border border-slate-200 dark:border-slate-700">
                  <div class="flex-shrink-0">
                    <.icon name="hero-user" class="size-5 text-sky-600 dark:text-sky-400" />
                  </div>
                  <span class="text-sm font-medium text-slate-700 dark:text-slate-300 truncate">
                    {@current_user.name}
                  </span>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                  Email
                </label>
                <div class="flex items-center gap-3 p-4 bg-gradient-to-r from-slate-50 to-sky-50/50 dark:from-slate-900 dark:to-slate-800 rounded-xl border border-slate-200 dark:border-slate-700">
                  <div class="flex-shrink-0">
                    <.icon name="hero-envelope" class="size-5 text-sky-600 dark:text-sky-400" />
                  </div>
                  <span class="text-sm font-medium text-slate-700 dark:text-slate-300 truncate">
                    {@current_user.email}
                  </span>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                  Phone
                </label>
                <div class="flex items-center gap-3 p-4 bg-gradient-to-r from-slate-50 to-sky-50/50 dark:from-slate-900 dark:to-slate-800 rounded-xl border border-slate-200 dark:border-slate-700">
                  <div class="flex-shrink-0">
                    <.icon name="hero-phone" class="size-5 text-sky-600 dark:text-sky-400" />
                  </div>
                  <span class="text-sm font-medium text-slate-700 dark:text-slate-300 truncate">
                    {@current_user.phone_number || "-"}
                  </span>
                </div>
              </div>

              <.input
                field={@form[:customer_comment]}
                type="textarea"
                label="Comments (Optional)"
                placeholder="Any special requests or notes..."
                rows="4"
              />
            </div>

            <div class="mt-6 flex items-center gap-3">
              <button
                type="submit"
                class="flex-1 bg-teal-600 hover:bg-teal-700 text-white font-semibold py-3 px-4 rounded-2xl transition-colors"
              >
                Confirm
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
