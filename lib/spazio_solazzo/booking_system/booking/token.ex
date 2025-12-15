defmodule SpazioSolazzo.BookingSystem.Booking.Token do
  @moduledoc """
  Generates secure, signed tokens for email actions.
  """
  alias SpazioSolazzoWeb.Endpoint

  def generate_customer_cancel_token(booking) do
    payload = %{booking_id: booking.id, role: :customer, action: "cancel"}
    Phoenix.Token.sign(Endpoint, signing_salt(), payload)
  end

  def generate_admin_tokens(booking) do
    confirm_payload = %{booking_id: booking.id, role: :admin, action: "confirm"}
    cancel_payload = %{booking_id: booking.id, role: :admin, action: "cancel"}

    %{
      confirm_token: Phoenix.Token.sign(Endpoint, signing_salt(), confirm_payload),
      cancel_token: Phoenix.Token.sign(Endpoint, signing_salt(), cancel_payload)
    }
  end

  # Helper to verify tokens in the Controller later
  def verify(token) do
    Phoenix.Token.verify(Endpoint, signing_salt(), token)
  end

  defp signing_salt() do
    Application.get_env(:spazio_solazzo, :booking_token_signing_salt)
  end
end
