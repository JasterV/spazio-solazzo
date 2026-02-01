defmodule SpazioSolazzo.BookingSystem.Booking.DecisionWorker do
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
          "decision" => decision,
          "rejection_reason" => rejection_reason
        }
      }) do
    case decision do
      "accepted" ->
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
        |> Email.accepted_user()
        |> SpazioSolazzo.Mailer.deliver!()

      "rejected" ->
        %{
          customer_name: customer_name,
          customer_email: customer_email,
          space_name: space_name,
          date: date,
          start_time: start_time,
          end_time: end_time,
          rejection_reason: rejection_reason
        }
        |> Email.rejected_user()
        |> SpazioSolazzo.Mailer.deliver!()
    end

    :ok
  end
end
