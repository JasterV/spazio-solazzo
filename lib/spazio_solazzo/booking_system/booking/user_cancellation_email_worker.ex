defmodule SpazioSolazzo.BookingSystem.Booking.UserCancellationEmailWorker do
  @moduledoc """
  Sends cancellation notification emails to administrators when a customer cancels a booking.
  """

  use Oban.Worker, queue: :booking_email, max_attempts: 3

  alias SpazioSolazzo.BookingSystem.Booking.Email

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "customer_name" => customer_name,
          "customer_email" => customer_email,
          "customer_phone" => customer_phone,
          "space_name" => space_name,
          "date" => date,
          "start_time" => start_time,
          "end_time" => end_time,
          "cancellation_reason" => cancellation_reason
        }
      }) do
    %{
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      space_name: space_name,
      date: date,
      start_time: start_time,
      end_time: end_time,
      cancellation_reason: cancellation_reason,
      admin_email: admin_email()
    }
    |> Email.booking_cancelled()
    |> SpazioSolazzo.Mailer.deliver!()

    :ok
  end

  defp admin_email do
    Application.get_env(:spazio_solazzo, :admin_email)
  end
end
