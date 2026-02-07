defmodule SpazioSolazzo.BookingSystem.Booking.RequestCreatedEmailWorkerTest do
  use SpazioSolazzo.DataCase, async: true

  alias SpazioSolazzo.BookingSystem.Booking.RequestCreatedEmailWorker
  alias Swoosh.Adapters.Local.Storage.Memory

  describe "perform/1" do
    test "sends confirmation email to customer" do
      job_args = %{
        "booking_id" => "test-booking-id",
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com",
        "customer_phone" => "+1234567890",
        "customer_comment" => "Test comment",
        "space_name" => "Coworking Space",
        "start_datetime" => "2026-02-02T09:00:00Z",
        "end_datetime" => "2026-02-02T13:00:00Z"
      }

      assert :ok = perform_job(RequestCreatedEmailWorker, job_args)

      # Verify customer email was sent
      emails = Memory.all()

      assert Enum.any?(emails, fn email ->
               email.to == [{"John Doe", "john@example.com"}]
             end)
    end

    test "sends notification email to admin" do
      job_args = %{
        "booking_id" => "test-booking-id",
        "customer_name" => "John Doe",
        "customer_email" => "john@example.com",
        "customer_phone" => "+1234567890",
        "customer_comment" => "Test comment",
        "space_name" => "Coworking Space",
        "start_datetime" => "2026-02-02T09:00:00Z",
        "end_datetime" => "2026-02-02T13:00:00Z"
      }

      admin_email = Application.get_env(:spazio_solazzo, :admin_email)

      assert :ok = perform_job(RequestCreatedEmailWorker, job_args)

      # Verify admin email was sent
      emails = Memory.all()

      assert Enum.any?(emails, fn email ->
               email.to == [{"", admin_email}]
             end)
    end

    test "sends both customer and admin emails in single job execution" do
      job_args = %{
        "booking_id" => "test-booking-id",
        "customer_name" => "Jane Smith",
        "customer_email" => "jane@example.com",
        "customer_phone" => "+1234567890",
        "customer_comment" => "Another test",
        "space_name" => "Meeting Room",
        "start_datetime" => "2026-02-03T14:00:00Z",
        "end_datetime" => "2026-02-03T18:00:00Z"
      }

      admin_email = Application.get_env(:spazio_solazzo, :admin_email)

      assert :ok = perform_job(RequestCreatedEmailWorker, job_args)

      # Both emails should be sent
      emails = Memory.all()
      assert length(emails) == 2

      email_recipients = Enum.map(emails, fn email -> email.to end)
      assert [{"Jane Smith", "jane@example.com"}] in email_recipients
      assert [{"", admin_email}] in email_recipients
    end

    test "customer email contains booking details" do
      job_args = %{
        "booking_id" => "test-booking-id",
        "customer_name" => "Test User",
        "customer_email" => "test@example.com",
        "customer_phone" => "+1234567890",
        "customer_comment" => "Test",
        "space_name" => "Music Room",
        "start_datetime" => "2026-02-04T10:00:00Z",
        "end_datetime" => "2026-02-04T12:00:00Z"
      }

      assert :ok = perform_job(RequestCreatedEmailWorker, job_args)

      emails = Memory.all()

      customer_email =
        Enum.find(emails, fn email ->
          email.to == [{"Test User", "test@example.com"}]
        end)

      assert customer_email != nil
      assert String.contains?(customer_email.html_body, "Music Room")
      assert String.contains?(customer_email.html_body, "Wednesday, February 04")
    end

    test "admin email contains customer information" do
      job_args = %{
        "booking_id" => "test-booking-id",
        "customer_name" => "Admin Test",
        "customer_email" => "admin.test@example.com",
        "customer_phone" => "+1234567890",
        "customer_comment" => "Admin comment",
        "space_name" => "Coworking Space",
        "start_datetime" => "2026-02-05T09:00:00Z",
        "end_datetime" => "2026-02-05T11:00:00Z"
      }

      admin_email = Application.get_env(:spazio_solazzo, :admin_email)

      assert :ok = perform_job(RequestCreatedEmailWorker, job_args)

      emails = Memory.all()

      admin_notification =
        Enum.find(emails, fn email ->
          email.to == [{"", admin_email}]
        end)

      assert admin_notification != nil
      assert String.contains?(admin_notification.html_body, "Admin Test")
      assert String.contains?(admin_notification.html_body, "admin.test@example.com")
    end
  end
end
