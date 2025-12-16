defmodule SpazioSolazzo.BookingSystem.EmailVerificationTest do
  use ExUnit.Case, async: true
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem
  alias SpazioSolazzo.BookingSystem.EmailVerification.CleanupWorker
  alias SpazioSolazzo.BookingSystem.EmailVerification.EmailWorker

  describe "create_verification_code" do
    test "creates verification with code, sends email & enqueues cleanup worker" do
      email = "test@example.com"

      {:ok, verification} = BookingSystem.create_verification_code(email)

      assert verification.email == email
      assert String.match?(verification.code, ~r/^\d{6}$/)

      assert_enqueued worker: CleanupWorker, args: %{"verification_id" => verification.id}

      assert_enqueued worker: EmailWorker,
                      args: %{
                        "verification_email" => verification.email,
                        "verification_code" => verification.code
                      }

      # Force jobs to execute
      Oban.drain_queue(queue: :default)

      assert %Swoosh.Email{
               subject: subject,
               html_body: html_body,
               to: sent_to
             } = Swoosh.Adapters.Local.Storage.Memory.pop()

      assert sent_to == [{"", email}]
      assert String.contains?(html_body, verification.code)
      assert subject == "Verify your booking at Spazio Solazzo"
    end

    test "generates unique codes for different verifications" do
      {:ok, verification1} = BookingSystem.create_verification_code("test1@example.com")
      {:ok, verification2} = BookingSystem.create_verification_code("test2@example.com")

      assert_enqueued worker: CleanupWorker, args: %{"verification_id" => verification1.id}
      assert_enqueued worker: CleanupWorker, args: %{"verification_id" => verification2.id}

      # Codes should be different (statistically very unlikely to be the same)
      assert verification1.code != verification2.code
    end
  end

  describe "verify_code" do
    setup do
      {:ok, verification} = BookingSystem.create_verification_code("test@example.com")

      topic = "email_verification:verification_code_expired:#{verification.id}"
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, topic)

      %{verification: verification, topic: topic}
    end

    test "successfully verifies with correct code", %{verification: verification, topic: topic} do
      {:ok, verified} = BookingSystem.verify_code(verification, verification.code)

      # Verifications should not fire expiration events
      refute_receive ^topic

      assert verified.id == verification.id

      # Verification should be deleted after successful verification
      assert {:error, _} = Ash.get(BookingSystem.EmailVerification, verification.id)
    end

    test "fails with incorrect code", %{verification: verification} do
      {:error, error} = BookingSystem.verify_code(verification, "000000")

      assert Ash.Error.error_descriptions(error) =~ "Invalid verification code"

      # Verification should still exist
      assert {:ok, _} = Ash.get(BookingSystem.EmailVerification, verification.id)
    end
  end

  describe "expire_verification_code" do
    test "verification can be expired & pubsub is published" do
      {:ok, verification} = BookingSystem.create_verification_code("test@example.com")
      topic = "email_verification:verification_code_expired:#{verification.id}"

      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, topic)

      assert :ok = BookingSystem.expire_verification_code(verification)

      assert_receive %{topic: ^topic, event: "expire"}

      assert {:error, _} = Ash.get(BookingSystem.EmailVerification, verification.id)
    end
  end
end
