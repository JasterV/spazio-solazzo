defmodule SpazioSolazzo.BookingSystem.EmailVerification.EmailWorker do
  use Oban.Worker, queue: :email_verification, max_attempts: 1

  alias SpazioSolazzo.BookingSystem.EmailVerification.Email

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "verification_email" => verification_email,
          "verification_code" => verification_code
        }
      }) do
    verification_email
    |> Email.verification_email(verification_code)
    |> SpazioSolazzo.Mailer.deliver()
  end
end
