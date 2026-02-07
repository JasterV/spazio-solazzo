defmodule SpazioSolazzo.BookingSystem.Booking.UserCancellationEmailWorker do
  @moduledoc """
  Sends cancellation notification emails to administrators when a customer cancels a booking.
  """

  use Oban.Worker, queue: :booking_email, max_attempts: 3

  alias SpazioSolazzo.BookingSystem.Booking.Email
  alias SpazioSolazzo.CalendarExt

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "customer_name" => customer_name,
          "customer_email" => customer_email,
          "customer_phone" => customer_phone,
          "space_name" => space_name,
          "start_datetime" => start_datetime_str,
          "end_datetime" => end_datetime_str,
          "cancellation_reason" => cancellation_reason
        }
      }) do
    {:ok, start_datetime, _} = DateTime.from_iso8601(start_datetime_str)
    {:ok, end_datetime, _} = DateTime.from_iso8601(end_datetime_str)

    %{
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      space_name: space_name,
      start_datetime: start_datetime,
      end_datetime: end_datetime,
      date: CalendarExt.format_datetime_date_only(start_datetime),
      start_time: DateTime.to_time(start_datetime),
      end_time: DateTime.to_time(end_datetime),
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
