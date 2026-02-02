defmodule SpazioSolazzo.BookingSystem.Booking.RequestCreatedEmailWorker do
  @moduledoc """
  Sends booking request confirmation emails to customers and notification emails to administrators.
  Triggered when a new booking request is created.
  """

  use Oban.Worker, queue: :booking_email, max_attempts: 3

  alias SpazioSolazzo.BookingSystem.Booking.Email
  alias SpazioSolazzo.CalendarExt

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "booking_id" => booking_id,
          "customer_name" => customer_name,
          "customer_email" => customer_email,
          "customer_phone" => customer_phone,
          "customer_comment" => customer_comment,
          "space_name" => space_name,
          "start_datetime" => start_datetime_str,
          "end_datetime" => end_datetime_str
        }
      }) do
    {:ok, start_datetime, _} = DateTime.from_iso8601(start_datetime_str)
    {:ok, end_datetime, _} = DateTime.from_iso8601(end_datetime_str)

    email_data = %{
      booking_id: booking_id,
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      customer_comment: customer_comment,
      space_name: space_name,
      start_datetime: start_datetime,
      end_datetime: end_datetime,
      date: CalendarExt.format_datetime_date_only(start_datetime),
      start_time: DateTime.to_time(start_datetime),
      end_time: DateTime.to_time(end_datetime),
      admin_email: admin_email()
    }

    email_data
    |> Email.user_booking_request_confirmation()
    |> SpazioSolazzo.Mailer.deliver!()

    email_data
    |> Email.admin_incoming_booking_request()
    |> SpazioSolazzo.Mailer.deliver!()

    :ok
  end

  defp admin_email do
    Application.get_env(:spazio_solazzo, :admin_email)
  end
end
