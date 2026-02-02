defmodule SpazioSolazzo.AuthHelpers do
  @moduledoc """
  Authentication helper functions for tests.

  Provides utilities to create and authenticate users via the magic link flow,
  simulating realistic authentication behavior in tests.
  """

  alias SpazioSolazzo.Accounts

  @doc """
  Creates a test session and logs the user into it.

  ## Parameters

    - `conn` - The test connection
    - `user` - User to log in

  ## Examples

      conn = log_in_user(conn, user)
  """
  def log_in_user(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> AshAuthentication.Phoenix.Plug.store_in_session(user)
  end

  @doc """
  Creates a user via magic link authentication without attaching to a connection.

  Useful for tests that need a user object but don't need an authenticated connection.

  ## Parameters

    - `email` - User's email address
    - `name` - Optional user's full name (defaults to "Test User")
    - `phone_number` - Optional phone number (defaults to nil)

  ## Examples

      user = register_user("test@example.com", "Test User", "+1234567890")
      user = register_user("user@example.com", "User Name")
      user = register_user("user@example.com")
  """
  def register_user(email, name \\ "Test user", phone_number \\ nil) do
    strategy = AshAuthentication.Info.strategy!(SpazioSolazzo.Accounts.User, :magic_link)

    {:ok, token} =
      AshAuthentication.Strategy.MagicLink.request_token_for_identity(strategy, email)

    # Sign in with magic link
    {:ok, user} =
      Accounts.sign_in_with_magic_link(
        token,
        false,
        name,
        phone_number,
        authorize?: false
      )

    user
  end
end
