defmodule SpazioSolazzo.BookingSystem.Booking.Email do
  @moduledoc """
  Sends booking confirmation emails to the customer and admin
  """
  import Swoosh.Email
  use SpazioSolazzoWeb, :verified_routes
  alias SpazioSolazzo.BookingSystem.Booking.Token

  # --- Customer Email ---
  def customer_confirmation(%{
        booking_id: booking_id,
        customer_name: customer_name,
        customer_email: customer_email,
        date: date,
        start_time: start_time,
        end_time: end_time
      }) do
    cancel_token = Token.generate_customer_cancel_token(booking_id)
    # The URL points to the controller handling the token logic
    cancel_url = url(~p"/bookings/action?token=#{cancel_token}&intent=cancel")

    new()
    |> to({customer_name, customer_email})
    |> from({"MyApp Bookings", "no-reply@myapp.com"})
    |> subject("Booking Confirmed: #{date}")
    |> html_body("""
      <h1>Booking Confirmed</h1>
      <p>Hello #{customer_name},</p>
      <p>Your booking details are as follows:</p>
      <ul>
        <li><strong>Date:</strong> #{date}</li>
        <li><strong>Time:</strong> #{start_time} - #{end_time}</li>
        <li><strong>Email:</strong> #{customer_email}</li>
      </ul>
      
      <p>If you need to cancel this booking, please click the button below:</p>
      
      <a href="#{cancel_url}" style="#{button_style(:red)}">
        Cancel Booking
      </a>
    """)
  end

  # --- Admin Email ---
  def admin_notification(%{
        booking_id: booking_id,
        customer_name: customer_name,
        customer_email: customer_email,
        date: date,
        start_time: start_time,
        end_time: end_time,
        admin_email: admin_email
      }) do
    tokens = Token.generate_admin_tokens(booking_id)

    confirm_url = url(~p"/bookings/action?token=#{tokens.confirm_token}&intent=confirm")
    cancel_url = url(~p"/bookings/action?token=#{tokens.cancel_token}&intent=cancel")

    new()
    |> to(admin_email)
    |> from({"MyApp System", "system@myapp.com"})
    |> subject("New Booking Action Required: #{customer_name}")
    |> html_body("""
      <h1>New Booking Received</h1>
      <p><strong>Customer:</strong> #{customer_name} (#{customer_email})</p>
      <p><strong>Date:</strong> #{date}</p>
      <p><strong>Time:</strong> #{start_time} - #{end_time}</p>
      
      <hr />
      
      <h3>Admin Actions</h3>
      <p>Please confirm if the customer has arrived and paid, or cancel the booking.</p>
      
      <div style="margin-bottom: 20px;">
        <a href="#{confirm_url}" style="#{button_style(:green)}">
          Confirm Arrival & Payment
        </a>
      </div>
      
      <div>
        <a href="#{cancel_url}" style="#{button_style(:red)}">
          Cancel Booking
        </a>
      </div>
    """)
  end

  # --- Helpers ---
  defp button_style(:red) do
    "background-color: #e53e3e; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;"
  end

  defp button_style(:green) do
    "background-color: #38a169; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;"
  end
end
