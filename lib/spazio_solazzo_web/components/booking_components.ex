defmodule SpazioSolazzoWeb.BookingComponents do
  @moduledoc """
  Reusable components for the booking flow.
  """
  use Phoenix.Component
  import SpazioSolazzoWeb.CoreComponents, only: [modal: 1]
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
            class="relative transform overflow-hidden rounded-3xl bg-white dark:bg-gray-800 px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-sm sm:p-6"
          >
            <div>
              <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-teal-100 dark:bg-teal-900/30">
                <svg
                  class="h-6 w-6 text-teal-600 dark:text-teal-400"
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
                <h3 class="text-lg font-semibold leading-6 text-gray-900 dark:text-white">
                  Booking Successful!
                </h3>
                <div class="mt-2">
                  <p class="text-sm text-gray-500 dark:text-gray-400">
                    Your booking has been confirmed. You will receive a confirmation email shortly.
                  </p>
                </div>
              </div>
            </div>
            <div class="mt-5 sm:mt-6">
              <button
                phx-click={@on_close}
                type="button"
                class="inline-flex w-full justify-center rounded-2xl bg-teal-600 px-3 py-3 text-sm font-semibold text-white shadow-lg hover:bg-teal-700 hover:shadow-xl focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-teal-600 transition-all"
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

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_close, :any, required: true

  @doc """
  Modal that notifies the users that their verification code has expired.
  """
  def email_verification_expired_modal(assigns) do
    ~H"""
    <div>
      <.modal :if={@show} id={@id} show on_cancel={@on_close}>
        <div>
          <div class="mt-6 p-4 bg-red-50 dark:bg-red-900/30 border border-red-200 dark:border-red-700 rounded-2xl">
            <div class="flex items-center gap-2 text-red-800 dark:text-red-200">
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                  clip-rule="evenodd"
                />
              </svg>
              <p class="font-semibold">Verification Code Expired</p>
            </div>
            <p class="mt-2 text-sm text-red-700 dark:text-red-300">
              Your verification code has expired. Please start over.
            </p>
          </div>
          <div class="mt-6">
            <button
              type="button"
              phx-click={@on_close}
              class="w-full bg-gray-200 hover:bg-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200 font-semibold py-3 px-4 rounded-2xl transition-colors"
            >
              Close
            </button>
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  attr :time_slot, :map, required: true
  attr :booked, :boolean, required: true
  attr :rest, :global

  @doc """
  Renders time slot buttons in different sizes showing availability status.
  """
  def time_slot(assigns) do
    ~H"""
    <button
      disabled={@booked}
      class={
        [
          # Base Compact Classes
          "p-4 border-2 transition-all text-center rounded-2xl",
          # State Classes
          if(@booked,
            do:
              "border-gray-300 dark:border-gray-600 bg-gray-100 dark:bg-gray-700 cursor-not-allowed opacity-75",
            else:
              "border-teal-400 dark:border-teal-600 hover:border-teal-600 dark:hover:border-teal-500 hover:bg-teal-50 dark:hover:bg-teal-900/30 cursor-pointer"
          )
        ]
      }
      {@rest}
    >
      <p class={["font-semibold", text_color(@booked, :primary)]}>
        {CalendarExt.format_time_range(@time_slot)}
      </p>
      <p class={["text-xs mt-1", text_color(@booked, :secondary)]}>
        {if @booked, do: "Booked", else: "Available"}
      </p>
    </button>
    """
  end

  defp text_color(booked, type) do
    if booked do
      "text-gray-500 dark:text-gray-400"
    else
      case type do
        :primary -> "text-gray-900 dark:text-white"
        :secondary -> "text-gray-600 dark:text-gray-300"
      end
    end
  end
end
