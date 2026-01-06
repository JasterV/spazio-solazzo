defmodule SpazioSolazzoWeb.BookingComponents.EmailVerificationExpiredComponent do
  @moduledoc """
  Displays a modal notifying users that their verification code has expired.
  """

  use SpazioSolazzoWeb, :html

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_close, :any, required: true

  def render(assigns) do
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
end
