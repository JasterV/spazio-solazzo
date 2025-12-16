defmodule SpazioSolazzo.BookingSystem.EmailVerification.CleanupWorker do
  use Oban.Worker, queue: :email_verification, max_attempts: 1

  alias SpazioSolazzo.BookingSystem

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"verification_id" => verification_id}}) do
    case Ash.get(BookingSystem.EmailVerification, verification_id) do
      {:ok, verification} ->
        BookingSystem.expire_verification_code!(verification)
        :ok

      {:error, _} ->
        # Verification already deleted, that's fine
        :ok
    end
  end
end
