defmodule SpazioSolazzo.BookingSystem.EmailVerificationTest do
  use SpazioSolazzo.DataCase
  import Swoosh.TestAssertions

  alias SpazioSolazzo.BookingSystem

  describe "EmailVerification.create" do
    test "creates verification with code and sends email" do
      email = "test@example.com"

      {:ok, verification} =
        BookingSystem.EmailVerification
        |> Ash.Changeset.for_create(:create, %{email: email})
        |> Ash.create()

      # Verify the verification record was created
      assert verification.email == email
      assert String.length(verification.code) == 6
      assert String.match?(verification.code, ~r/^\d{6}$/)
      assert verification.expires_at != nil

      # Verify expiration is set correctly (60 seconds by default)
      now = DateTime.utc_now()
      diff = DateTime.diff(verification.expires_at, now, :second)
      assert diff > 55 and diff <= 60

      # Verify email was sent using Swoosh test assertions
      assert_email_sent(fn email_sent ->
        email_sent.to == [{"", email}] and
          email_sent.subject == "Verify your booking at Spazio Solazzo" and
          String.contains?(email_sent.html_body, verification.code)
      end)
    end

    test "generates unique codes for different verifications" do
      {:ok, verification1} =
        BookingSystem.EmailVerification
        |> Ash.Changeset.for_create(:create, %{email: "test1@example.com"})
        |> Ash.create()

      {:ok, verification2} =
        BookingSystem.EmailVerification
        |> Ash.Changeset.for_create(:create, %{email: "test2@example.com"})
        |> Ash.create()

      # Codes should be different (statistically very unlikely to be the same)
      assert verification1.code != verification2.code
    end
  end

  describe "EmailVerification.verify" do
    setup do
      {:ok, verification} =
        BookingSystem.EmailVerification
        |> Ash.Changeset.for_create(:create, %{email: "test@example.com"})
        |> Ash.create()

      %{verification: verification}
    end

    test "successfully verifies with correct code", %{verification: verification} do
      {:ok, verified} =
        verification
        |> Ash.Changeset.for_update(:verify, %{code: verification.code})
        |> Ash.update()

      assert verified.id == verification.id

      # Verification should be deleted after successful verification
      assert {:error, _} = Ash.get(BookingSystem.EmailVerification, verification.id)
    end

    test "fails with incorrect code", %{verification: verification} do
      {:error, error} =
        verification
        |> Ash.Changeset.for_update(:verify, %{code: "000000"})
        |> Ash.update()

      error_messages = Ash.Error.error_descriptions(error)
      assert error_messages =~ "Invalid verification code"

      # Verification should still exist
      assert {:ok, _} = Ash.get(BookingSystem.EmailVerification, verification.id)
    end

    test "fails with expired code", %{verification: verification} do
      # Manually update expires_at to be in the past
      expired_verification =
        verification
        |> Ash.Changeset.for_update(:update, %{})
        |> Ash.Changeset.force_change_attribute(
          :expires_at,
          DateTime.add(DateTime.utc_now(), -10, :second)
        )
        |> Ash.update!(authorize?: false)

      {:error, error} =
        expired_verification
        |> Ash.Changeset.for_update(:verify, %{code: expired_verification.code})
        |> Ash.update()

      error_messages = Ash.Error.error_descriptions(error)
      assert error_messages =~ "expired"
    end
  end

  describe "EmailVerification cleanup" do
    test "verification can be deleted" do
      {:ok, verification} =
        BookingSystem.EmailVerification
        |> Ash.Changeset.for_create(:create, %{email: "test@example.com"})
        |> Ash.create()

      assert :ok = Ash.destroy(verification)
      assert {:error, _} = Ash.get(BookingSystem.EmailVerification, verification.id)
    end
  end
end
