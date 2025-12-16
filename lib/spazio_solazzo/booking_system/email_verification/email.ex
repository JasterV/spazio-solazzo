defmodule SpazioSolazzo.BookingSystem.EmailVerification.Email do
  @moduledoc """
  Sends verification code emails to customers.
  """

  use Phoenix.Swoosh,
    view: SpazioSolazzoWeb.EmailView,
    layout: {SpazioSolazzoWeb.EmailView, :layout}

  import Swoosh.Email

  def verification_email(customer_email, code) do
    assigns = %{
      code: code,
      timeout: verification_timeout(),
      subject: "Verify Your Booking"
    }

    new()
    |> to(customer_email)
    |> from({"Spazio Solazzo", spazio_solazzo_email()})
    |> subject(assigns.subject)
    |> render_body("verification_email.html", assigns)
  end

  defp verification_timeout do
    Application.get_env(:spazio_solazzo, :verification_timeout)
  end

  defp spazio_solazzo_email do
    Application.get_env(:spazio_solazzo, :spazio_solazzo_email)
  end
end
