defmodule SpazioSolazzo.BookingSystem.Booking.EmailWorker do
  use Oban.Worker, queue: :default, max_attempts: 1

  alias SpazioSolazzo.BookingSystem.Booking.Email

  @admin_email "admin@myapp.com"

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"booking" => booking}}) do
    booking
    |> Email.customer_confirmation()
    |> SpazioSolazzo.Mailer.deliver()

    # 2. Send Admin Email
    booking
    |> Email.admin_notification(@admin_email)
    |> SpazioSolazzo.Mailer.deliver()
  end
end
