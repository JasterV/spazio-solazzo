defmodule SpazioSolazzoWeb.BookingComponents.EmailVerificationComponent do
  @moduledoc """
  Standalone LiveComponent for email verification with OTP.
  Completely decoupled from bookings - only knows about EmailVerification.
  """
  use SpazioSolazzoWeb, :live_component

  alias SpazioSolazzo.BookingSystem

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:otp_form, to_form(%{"code" => ""}))
      |> assign(:error, nil)

    {:ok, socket}
  end

  def handle_event("validate_otp", %{"code" => code}, socket) do
    otp_form = to_form(%{"code" => code})
    {:noreply, assign(socket, otp_form: otp_form, error: nil)}
  end

  def handle_event("submit_otp", %{"code" => code}, socket) do
    verification_id = socket.assigns.verification_id

    case Ash.get(BookingSystem.EmailVerification, verification_id) do
      {:ok, verification} ->
        case verification
             |> Ash.Changeset.for_update(:verify, %{code: code})
             |> Ash.update() do
          {:ok, _verification} ->
            # Send success message to parent
            send(self(), :email_verified)
            {:noreply, socket}

          {:error, _} ->
            {:noreply, assign(socket, error: "Invalid verification code")}
        end

      {:error, _} ->
        {:noreply, assign(socket, error: "Verification code expired")}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal :if={@show} id={@id} show on_cancel={@on_cancel}>
        <:title>Verify Your Email</:title>
        <:subtitle>
          We sent a verification code to {@verification_email}
        </:subtitle>

        <div>
          <div class="mt-6">
            <div class="p-4 bg-teal-50 dark:bg-teal-900/30 border border-teal-200 dark:border-teal-700 rounded-2xl mb-4">
              <p class="text-sm text-teal-900 dark:text-teal-100">
                A 6-digit verification code has been sent to your email. Please enter it below.
              </p>
            </div>

            <%= if @error do %>
              <div class="mb-4 p-3 bg-red-50 dark:bg-red-900/30 border border-red-200 dark:border-red-700 rounded-2xl text-red-800 dark:text-red-200 text-sm">
                {@error}
              </div>
            <% end %>

            <.form
              for={@otp_form}
              id={"otp-form-#{@id}"}
              phx-submit="submit_otp"
              phx-change="validate_otp"
              phx-target={@myself}
            >
              <div class="space-y-4">
                <.input
                  field={@otp_form[:code]}
                  type="text"
                  label="Verification Code"
                  placeholder="000000"
                  maxlength="6"
                  pattern="[0-9]{6}"
                  autocomplete="off"
                  required
                />
              </div>

              <div class="mt-6 flex items-center gap-3">
                <button
                  type="submit"
                  class="flex-1 bg-teal-600 hover:bg-teal-700 text-white font-semibold py-3 px-4 rounded-2xl transition-colors shadow-lg hover:shadow-xl disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Verify
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
        </div>
      </.modal>
    </div>
    """
  end
end
