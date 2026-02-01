defmodule SpazioSolazzo.BookingSystem.Booking.NewRequestWorker do
  @moduledoc """
  Sends booking request confirmation emails to customers and notification emails to administrators.
  Triggered when a new booking request is created.
  """

  use Oban.Worker, queue: :booking_email, max_attempts: 3

  alias SpazioSolazzo.BookingSystem.Booking.Email

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "booking_id" => booking_id,
          "customer_name" => customer_name,
          "customer_email" => customer_email,
          "customer_phone" => customer_phone,
          "customer_comment" => customer_comment,
          "space_name" => space_name,
          "date" => date,
          "start_time" => start_time,
          "end_time" => end_time
        }
      }) do
    email_data = %{
      booking_id: booking_id,
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      customer_comment: customer_comment,
      space_name: space_name,
      date: date,
      start_time: start_time,
      end_time: end_time,
      admin_email: admin_email()
    }

    email_data
    |> Email.request_received_user()
    |> SpazioSolazzo.Mailer.deliver!()

    email_data
    |> Email.new_request_admin()
    |> SpazioSolazzo.Mailer.deliver!()

    :ok
  end

  defp admin_email do
    Application.get_env(:spazio_solazzo, :admin_email)
  end
end
