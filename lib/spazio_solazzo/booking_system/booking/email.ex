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

  def user_booking_request_confirmation(%{
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
    |> render_body("user_booking_request_confirmation.html", assigns)
  end

  def admin_incoming_booking_request(%{
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
    dashboard_url = url(~p"/admin/bookings")

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
    |> render_body("admin_incoming_booking_request.html", assigns)
  end

  def booking_cancelled(%{
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
    |> render_body("booking_cancelled.html", assigns)
  end

  def booking_request_approved(%{
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
    |> render_body("booking_request_approved.html", assigns)
  end

  def booking_request_rejected(%{
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
    |> render_body("booking_request_rejected.html", assigns)
  end

  defp spazio_solazzo_email do
    Application.get_env(:spazio_solazzo, :spazio_solazzo_email)
  end

  defp front_office_phone_number do
    Application.get_env(:spazio_solazzo, :front_office_phone_number)
  end
end
