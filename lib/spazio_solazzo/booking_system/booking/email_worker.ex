defmodule SpazioSolazzo.BookingSystem.Booking.EmailWorker do
  use Oban.Worker, queue: :booking_email, max_attempts: 1

  alias SpazioSolazzo.BookingSystem.Booking.Email

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "booking_id" => booking_id,
          "customer_name" => customer_name,
          "customer_email" => customer_email,
          "customer_phone" => customer_phone,
          "customer_comment" => customer_comment,
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
      date: date,
      start_time: start_time,
      end_time: end_time,
      admin_email: admin_email()
    }

    email_data
    |> Email.customer_confirmation()
    |> SpazioSolazzo.Mailer.deliver!()

    email_data
    |> Email.admin_notification()
    |> SpazioSolazzo.Mailer.deliver!()
  end

  defp admin_email do
    Application.get_env(:spazio_solazzo, :admin_email)
  end
end
