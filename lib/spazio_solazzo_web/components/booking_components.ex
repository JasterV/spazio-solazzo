defmodule SpazioSolazzoWeb.BookingComponents do
  @moduledoc """
  Reusable components for the booking flow.
  """
  use Phoenix.Component
  alias SpazioSolazzo.CalendarExt

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_close, :any, required: true

  @doc """
  Success modal displayed when a booking is completed.
  """
  def booking_confirmation_modal(assigns) do
    ~H"""
    <div
      :if={@show}
      id={@id}
      class="relative z-50"
      role="dialog"
      aria-modal="true"
    >
      <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" />
      <div class="fixed inset-0 z-10 overflow-y-auto">
        <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
          <div
            id={"#{@id}-container"}
            class="relative transform overflow-hidden rounded-3xl bg-base-100 px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-sm sm:p-6"
          >
            <div>
              <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-success/10">
                <svg
                  class="h-6 w-6 text-success"
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
              <div class="mt-3 text-center sm:mt-5">
                <h3 class="text-lg font-semibold leading-6 text-base-content">
                  Booking Successful!
                </h3>
                <div class="mt-2">
                  <p class="text-sm text-neutral">
                    Your booking has been confirmed. You will receive a confirmation email shortly.
                  </p>
                </div>
              </div>
            </div>
            <div class="mt-5 sm:mt-6">
              <button
                phx-click={@on_close}
                type="button"
                class="btn btn-success w-full rounded-2xl text-white shadow-lg hover:shadow-xl transition-all"
              >
                Got it!
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :time_slot, :map, required: true
  attr :booked, :boolean, required: true

  @doc """
  Renders time slot buttons in different sizes showing availability status.
  """
  def time_slot(assigns) do
    ~H"""
    <button
      phx-click={unless @booked, do: "select_slot"}
      phx-value-time_slot_id={@time_slot.id}
      disabled={@booked}
      class={[
        "group w-full flex items-center justify-between p-4 rounded-xl border-2 transition-all duration-200",
        if(@booked,
          do: "border-base-300 bg-base-200 cursor-not-allowed opacity-75",
          else:
            "border-secondary/40 hover:border-secondary bg-transparent hover:bg-secondary/5 cursor-pointer"
        )
      ]}
    >
      <span class={[
        "text-lg font-bold transition-colors",
        if(@booked,
          do: "text-neutral",
          else: "text-base-content group-hover:text-secondary"
        )
      ]}>
        {CalendarExt.format_time_range(@time_slot)}
      </span>
      <span class={[
        "text-xs font-medium",
        if(@booked, do: "text-neutral", else: "text-secondary")
      ]}>
        {if @booked, do: "Booked", else: "Available"}
      </span>
    </button>
    """
  end
end
