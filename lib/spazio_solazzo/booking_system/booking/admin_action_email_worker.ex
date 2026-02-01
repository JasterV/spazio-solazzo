defmodule SpazioSolazzo.BookingSystem.Booking.AdminActionEmailWorker do
  @moduledoc """
  Sends emails when an admin approves or rejects a booking request.
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
          "space_name" => space_name,
          "date" => date,
          "start_time" => start_time,
          "end_time" => end_time,
          "action" => "accepted"
        }
      }) do
    %{
      booking_id: booking_id,
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      space_name: space_name,
      date: date,
      start_time: start_time,
      end_time: end_time
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
          "date" => date,
          "start_time" => start_time,
          "end_time" => end_time,
          "action" => "rejected",
          "rejection_reason" => rejection_reason
        }
      }) do
    %{
      customer_name: customer_name,
      customer_email: customer_email,
      space_name: space_name,
      date: date,
      start_time: start_time,
      end_time: end_time,
      rejection_reason: rejection_reason
    }
    |> Email.booking_request_rejected()
    |> SpazioSolazzo.Mailer.deliver!()

    :ok
  end
end
