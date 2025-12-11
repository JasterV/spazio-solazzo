defmodule SpazioSolazzoWeb.AuthController do
  use SpazioSolazzoWeb, :controller
  use AshAuthentication.Phoenix.Controller

  alias SpazioSolazzo.Accounts

  def magic_sign_in(conn, %{"token" => token, "remember_me" => remember_me} = args) do
    name = Map.get(args, "name")
    phone_number = Map.get(args, "phone_number")

    result =
      Accounts.sign_in_with_magic_link(
        token,
        remember_me == "true",
        name,
        phone_number,
        authorize?: false
      )

    case result do
      {:ok, user} ->
        auth_success(conn, user)

      {:error, _error} ->
        auth_failure(conn)
    end
  end

  defp auth_success(conn, user) do
    return_to = get_session(conn, :return_to) || ~p"/"
    remember_me = Ash.Resource.get_metadata(user, :remember_me)

    conn =
      case remember_me do
        nil ->
          conn

        %{max_age: max_age, token: token} ->
          put_resp_cookie(conn, "remember_me", token,
            http_only: true,
            secure: true,
            same_site: "lax",
            max_age: max_age
          )
      end

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    |> assign(:current_user, user)
    |> put_flash(:info, "You are now signed in")
    |> redirect(to: return_to)
  end

  defp auth_failure(conn) do
    conn
    |> put_flash(:error, "Authentication failed. Please try again.")
    |> redirect(to: ~p"/sign-in")
  end

  def sign_out(conn, _params) do
    conn
    |> clear_session(:spazio_solazzo)
    |> AshAuthentication.Strategy.RememberMe.Plug.Helpers.delete_all_remember_me_cookies(
      :spazio_solazzo
    )
    |> put_flash(:info, "You are now signed out")
    |> redirect(to: ~p"/")
  end
end
