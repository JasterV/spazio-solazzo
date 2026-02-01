defmodule SpazioSolazzo.BookingSystem.Booking.Email do
  @moduledoc """
  Sends booking confirmation emails to the customer and admin
  """
  use Phoenix.Swoosh,
    view: SpazioSolazzoWeb.EmailView,
    layout: {SpazioSolazzoWeb.EmailView, :layout}

  import Swoosh.Email

  use SpazioSolazzoWeb, :verified_routes
  alias SpazioSolazzo.BookingSystem.Booking.Token

  def request_received_user(%{
        booking_id: booking_id,
        customer_name: customer_name,
        customer_email: customer_email,
        customer_phone: customer_phone,
        customer_comment: customer_comment,
        space_name: space_name,
        date: date,
        start_time: start_time,
        end_time: end_time
      }) do
    cancel_token = Token.generate_customer_cancel_token(booking_id)
    cancel_url = url(~p"/bookings/cancel?token=#{cancel_token}")

    assigns = %{
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      customer_comment: customer_comment,
      space_name: space_name,
      date: date,
      start_time: start_time,
      end_time: end_time,
      cancel_url: cancel_url,
      front_office_phone_number: front_office_phone_number(),
      subject: "Request Received: #{date}"
    }

    new()
    |> to({customer_name, customer_email})
    |> from({"Spazio Solazzo", spazio_solazzo_email()})
    |> subject(assigns.subject)
    |> render_body("request_received_user.html", assigns)
  end

  def accepted_user(%{
        booking_id: booking_id,
        customer_name: customer_name,
        customer_email: customer_email,
        customer_phone: customer_phone,
        space_name: space_name,
        date: date,
        start_time: start_time,
        end_time: end_time
      }) do
    cancel_token = Token.generate_customer_cancel_token(booking_id)
    cancel_url = url(~p"/bookings/cancel?token=#{cancel_token}")

    assigns = %{
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      space_name: space_name,
      date: date,
      start_time: start_time,
      end_time: end_time,
      cancel_url: cancel_url,
      front_office_phone_number: front_office_phone_number(),
      subject: "Booking Approved: #{date}"
    }

    new()
    |> to({customer_name, customer_email})
    |> from({"Spazio Solazzo", spazio_solazzo_email()})
    |> subject(assigns.subject)
    |> render_body("accepted_user.html", assigns)
  end

  def rejected_user(%{
        customer_name: customer_name,
        customer_email: customer_email,
        space_name: space_name,
        date: date,
        start_time: start_time,
        end_time: end_time,
        rejection_reason: rejection_reason
      }) do
    assigns = %{
      customer_name: customer_name,
      customer_email: customer_email,
      space_name: space_name,
      date: date,
      start_time: start_time,
      end_time: end_time,
      rejection_reason: rejection_reason,
      front_office_phone_number: front_office_phone_number(),
      subject: "Booking Request Update: #{date}"
    }

    new()
    |> to({customer_name, customer_email})
    |> from({"Spazio Solazzo", spazio_solazzo_email()})
    |> subject(assigns.subject)
    |> render_body("rejected_user.html", assigns)
  end

  def customer_confirmation(%{
        booking_id: booking_id,
        customer_name: customer_name,
        customer_email: customer_email,
        customer_phone: customer_phone,
        customer_comment: customer_comment,
        date: date,
        start_time: start_time,
        end_time: end_time
      }) do
    cancel_token = Token.generate_customer_cancel_token(booking_id)
    cancel_url = url(~p"/bookings/cancel?token=#{cancel_token}")

    assigns = %{
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      customer_comment: customer_comment,
      date: date,
      start_time: start_time,
      end_time: end_time,
      cancel_url: cancel_url,
      front_office_phone_number: front_office_phone_number(),
      subject: "Booking Confirmed: #{date}"
    }

    new()
    |> to({customer_name, customer_email})
    |> from({"Spazio Solazzo", spazio_solazzo_email()})
    |> subject(assigns.subject)
    |> render_body("customer_confirmation.html", assigns)
  end

  def new_request_admin(%{
        customer_name: customer_name,
        customer_email: customer_email,
        customer_phone: customer_phone,
        customer_comment: customer_comment,
        space_name: space_name,
        date: date,
        start_time: start_time,
        end_time: end_time,
        admin_email: admin_email
      }) do
    dashboard_url = url(~p"/admin/dashboard")

    assigns = %{
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      customer_comment: customer_comment,
      space_name: space_name,
      date: date,
      start_time: start_time,
      end_time: end_time,
      dashboard_url: dashboard_url,
      subject: "New Booking Request: #{customer_name}"
    }

    new()
    |> to(admin_email)
    |> from({"Spazio Solazzo", spazio_solazzo_email()})
    |> subject(assigns.subject)
    |> render_body("new_request_admin.html", assigns)
  end

  def cancelled_admin(%{
        customer_name: customer_name,
        customer_email: customer_email,
        customer_phone: customer_phone,
        space_name: space_name,
        date: date,
        start_time: start_time,
        end_time: end_time,
        cancellation_reason: cancellation_reason,
        admin_email: admin_email
      }) do
    assigns = %{
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      space_name: space_name,
      date: date,
      start_time: start_time,
      end_time: end_time,
      cancellation_reason: cancellation_reason,
      subject: "Booking Cancelled: #{customer_name}"
    }

    new()
    |> to(admin_email)
    |> from({"Spazio Solazzo", spazio_solazzo_email()})
    |> subject(assigns.subject)
    |> render_body("cancelled_admin.html", assigns)
  end

  # --- Admin Email ---
  def admin_notification(%{
        booking_id: booking_id,
        customer_name: customer_name,
        customer_email: customer_email,
        customer_phone: customer_phone,
        customer_comment: customer_comment,
        date: date,
        start_time: start_time,
        end_time: end_time,
        admin_email: admin_email
      }) do
    tokens = Token.generate_admin_tokens(booking_id)

    confirm_url = url(~p"/bookings/confirm?token=#{tokens.confirm_token}")
    cancel_url = url(~p"/bookings/cancel?token=#{tokens.cancel_token}")

    assigns = %{
      customer_name: customer_name,
      customer_email: customer_email,
      customer_phone: customer_phone,
      customer_comment: customer_comment,
      date: date,
      start_time: start_time,
      end_time: end_time,
      confirm_url: confirm_url,
      cancel_url: cancel_url,
      subject: "New Booking Action Required: #{customer_name}"
    }

    new()
    |> to(admin_email)
    |> from({"Spazio Solazzo", spazio_solazzo_email()})
    |> subject(assigns.subject)
    |> render_body("admin_notification.html", assigns)
  end

  defp spazio_solazzo_email do
    Application.get_env(:spazio_solazzo, :spazio_solazzo_email)
  end

  defp front_office_phone_number do
    Application.get_env(:spazio_solazzo, :front_office_phone_number)
  end
end
