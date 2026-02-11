defmodule SpazioSolazzo.BookingSystem.Booking.AdminActionEmailWorker do
  @moduledoc """
  Sends emails when an admin approves or rejects a booking request.
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
          "space_name" => space_name,
          "space_slug" => space_slug,
          "start_datetime" => start_datetime_str,
          "end_datetime" => end_datetime_str,
          "action" => "accepted"
        }
      }) do
    {:ok, start_datetime, _} = DateTime.from_iso8601(start_datetime_str)
    {:ok, end_datetime, _} = DateTime.from_iso8601(end_datetime_str)

    %{
      booking_id: booking_id,
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      space_name: space_name,
      space_slug: space_slug,
      start_datetime: start_datetime,
      end_datetime: end_datetime,
      date: CalendarExt.format_datetime_date_only(start_datetime),
      start_time: DateTime.to_time(start_datetime),
      end_time: DateTime.to_time(end_datetime)
    }
    |> Email.booking_request_approved()
    |> SpazioSolazzo.Mailer.deliver!()

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "customer_name" => customer_name,
          "customer_email" => customer_email,
          "space_name" => space_name,
          "start_datetime" => start_datetime_str,
          "end_datetime" => end_datetime_str,
          "action" => "rejected",
          "rejection_reason" => rejection_reason
        }
      }) do
    {:ok, start_datetime, _} = DateTime.from_iso8601(start_datetime_str)
    {:ok, end_datetime, _} = DateTime.from_iso8601(end_datetime_str)

    %{
      customer_name: customer_name,
      customer_email: customer_email,
      space_name: space_name,
      start_datetime: start_datetime,
      end_datetime: end_datetime,
      date: CalendarExt.format_datetime_date_only(start_datetime),
      start_time: DateTime.to_time(start_datetime),
      end_time: DateTime.to_time(end_datetime),
      rejection_reason: rejection_reason
    }
    |> Email.booking_request_rejected()
    |> SpazioSolazzo.Mailer.deliver!()

    :ok
  end
end
