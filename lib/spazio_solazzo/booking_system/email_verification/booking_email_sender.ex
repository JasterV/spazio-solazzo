defmodule SpazioSolazzo.BookingSystem.EmailVerification.EmailSender do
  @moduledoc """
  Sends verification code emails to customers.
  """

  import Swoosh.Email

  def send_verification_code(customer_email, code) do
    email =
      new()
      |> to(customer_email)
      |> from({"Spazio Solazzo", "noreply@spaziosolazzo.com"})
      |> subject("Verify your booking at Spazio Solazzo")
      |> html_body("""
      <h1>Verify Your Booking</h1>
      <p>Hi,</p>
      <p>Thank you for booking with Spazio Solazzo!</p>
      <p>Your verification code is:</p>
      <h2 style="font-size: 32px; letter-spacing: 8px; font-family: monospace;">#{code}</h2>
      <p>This code will expire in 60 seconds.</p>
      <p>If you didn't make this booking, you can safely ignore this email.</p>
      """)

    SpazioSolazzo.Mailer.deliver(email)
  end
end
