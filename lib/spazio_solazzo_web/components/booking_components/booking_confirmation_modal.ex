defmodule SpazioSolazzoWeb.BookingComponents.BookingConfirmationModal do
  @moduledoc """
  Displays a success modal when a booking is completed.
  """

  use SpazioSolazzoWeb, :html

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_close, :any, required: true

  def render(assigns) do
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
end
