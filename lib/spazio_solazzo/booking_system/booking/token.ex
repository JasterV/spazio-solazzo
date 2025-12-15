defmodule SpazioSolazzo.BookingSystem.Booking.Token do
  @moduledoc """
  Generates secure, signed tokens for email actions.
  """
  alias SpazioSolazzoWeb.Endpoint

  @salt "booking_action_salt"
  # 2 weeks in seconds
  @max_age 1_209_600

  def generate_customer_cancel_token(booking) do
    payload = %{booking_id: booking.id, role: :customer, action: "cancel"}
    Phoenix.Token.sign(Endpoint, @salt, payload)
  end

  def generate_admin_tokens(booking) do
    confirm_payload = %{booking_id: booking.id, role: :admin, action: "confirm"}
    cancel_payload = %{booking_id: booking.id, role: :admin, action: "cancel"}

    %{
      confirm_token: Phoenix.Token.sign(Endpoint, @salt, confirm_payload),
      cancel_token: Phoenix.Token.sign(Endpoint, @salt, cancel_payload)
    }
  end

  # Helper to verify tokens in the Controller later
  def verify(token) do
    Phoenix.Token.verify(Endpoint, @salt, token, max_age: @max_age)
  end
end
