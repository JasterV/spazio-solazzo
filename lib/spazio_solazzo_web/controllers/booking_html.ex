defmodule SpazioSolazzoWeb.BookingHTML do
  use SpazioSolazzoWeb, :html

  embed_templates "booking_html/*"

  # Helper to generate a user-friendly title based on the action name
  def action_title(:cancel), do: "Booking Cancelled"
  def action_title(:confirm), do: "Booking Confirmed"
  def action_title(_), do: "Action Successful"

  # Helper to generate a descriptive message
  def action_message(:cancel),
    do: "The booking has been successfully cancelled. No further action is required."

  def action_message(:confirm),
    do: "The booking has been marked as paid and completed. The customer has been checked in."

  def action_message(_), do: "The requested action has been processed successfully."
end
