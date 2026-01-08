defmodule SpazioSolazzo.Accounts.User.Senders.SendMagicLinkEmail do
  @moduledoc """
  Sends a magic link email
  """

  use AshAuthentication.Sender
  use SpazioSolazzoWeb, :verified_routes

  import Swoosh.Email
  alias SpazioSolazzo.Mailer

  @impl true
  def send(user_or_email, token, _) do
    # if you get a user, its for a user that already exists.
    # if you get an email, then the user does not yet exist.

    email =
      case user_or_email do
        %{email: email} -> email
        email -> email
      end

    new()
    |> from({"Spazio Solazzo", "noreply@example.com"})
    |> to(to_string(email))
    |> subject("Your login link")
    |> html_body(body(token: token, email: email))
    |> Mailer.deliver!()
  end

  defp body(params) do
    magic_link_url = url(~p"/sign-in/callback?token=#{params[:token]}")

    """
    <p>Hello, #{params[:email]}! Click this link to sign in:</p>
    <p><a href="#{magic_link_url}">#{magic_link_url}</a></p>
    """
  end
end
