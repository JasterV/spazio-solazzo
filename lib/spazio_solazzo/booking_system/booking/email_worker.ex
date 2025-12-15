defmodule SpazioSolazzo.BookingSystem.Booking.EmailWorker do
  use Oban.Worker, queue: :default, max_attempts: 1

  alias SpazioSolazzo.BookingSystem.Booking.Email

  @admin_email "admin@myapp.com"

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "booking_id" => booking_id,
          "customer_name" => customer_name,
          "customer_email" => customer_email,
          "date" => date,
          "start_time" => start_time,
          "end_time" => end_time
        }
      }) do
    email_data = %{
      booking_id: booking_id,
      customer_name: customer_name,
      customer_email: customer_email,
      date: date,
      start_time: start_time,
      end_time: end_time,
      admin_email: @admin_email
    }

    email_data
    |> Email.customer_confirmation()
    |> SpazioSolazzo.Mailer.deliver()

    email_data
    |> Email.admin_notification()
    |> SpazioSolazzo.Mailer.deliver()
  end
end
