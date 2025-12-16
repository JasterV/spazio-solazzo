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
      assert is_binary(verification.code_hash)
      assert String.starts_with?(verification.code_hash, "$2")

      assert_enqueued worker: CleanupWorker, args: %{"verification_id" => verification.id}
      assert_enqueued worker: EmailWorker

      # Force jobs to execute
      Oban.drain_queue(queue: :email_verification)

      assert %Swoosh.Email{
               subject: subject,
               html_body: html_body,
               to: sent_to
             } = Swoosh.Adapters.Local.Storage.Memory.pop()

      assert sent_to == [{"", email}]

      [_, code] = Regex.run(~r/(\d{6})/, html_body)

      assert Bcrypt.verify_pass(code, verification.code_hash)
      refute verification.code_hash == code
      assert subject == "Verify your booking at Spazio Solazzo"
    end

    test "generates unique codes for different verifications" do
      {:ok, verification1} = BookingSystem.create_verification_code("test1@example.com")
      {:ok, verification2} = BookingSystem.create_verification_code("test2@example.com")

      assert_enqueued worker: CleanupWorker, args: %{"verification_id" => verification1.id}
      assert_enqueued worker: CleanupWorker, args: %{"verification_id" => verification2.id}

      # Force jobs to execute and capture sent codes
      Oban.drain_queue(queue: :email_verification)

      assert %Swoosh.Email{html_body: html_body2} = Swoosh.Adapters.Local.Storage.Memory.pop()
      assert %Swoosh.Email{html_body: html_body1} = Swoosh.Adapters.Local.Storage.Memory.pop()

      [_, code1] = Regex.run(~r/(\d{6})/, html_body1)
      [_, code2] = Regex.run(~r/(\d{6})/, html_body2)

      assert code1 != code2
      assert Bcrypt.verify_pass(code1, verification1.code_hash)
      assert Bcrypt.verify_pass(code2, verification2.code_hash)
    end
  end

  describe "verify_code" do
    setup do
      {:ok, verification} = BookingSystem.create_verification_code("test@example.com")

      # Drain the email job and extract the raw code so tests can use it
      Oban.drain_queue(queue: :email_verification)

      assert %Swoosh.Email{html_body: html_body} = Swoosh.Adapters.Local.Storage.Memory.pop()

      [_, code] = Regex.run(~r/(\d{6})/, html_body)

      topic = "email_verification:verification_code_expired:#{verification.id}"
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, topic)

      %{verification: verification, topic: topic, code: code}
    end

    test "successfully verifies with correct code", %{
      verification: verification,
      topic: topic,
      code: code
    } do
      {:ok, verified} = BookingSystem.verify_code(verification, code)

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
