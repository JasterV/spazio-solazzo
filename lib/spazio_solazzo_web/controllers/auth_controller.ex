defmodule SpazioSolazzoWeb.AuthController do
  use SpazioSolazzoWeb, :controller
  use AshAuthentication.Phoenix.Controller

  alias AshAuthentication.Jwt
  alias SpazioSolazzo.Accounts.User

  def callback(conn, %{"token" => token}) do
    case Jwt.verify(token, :spazio_solazzo) do
      {:ok, %{"sub" => subject}, _resource} ->
        # Use your User resource's read action to fetch the user by subject
        case User
             |> Ash.Query.for_read(:get_by_subject, %{subject: subject})
             |> Ash.read_one(authorize?: false) do
          {:ok, user} when not is_nil(user) ->
            user = Ash.Resource.put_metadata(user, :token, token)
            success(conn, :magic_link, user, token)

          _ ->
            failure(conn, %{})
        end

      {:error, _} ->
        failure(conn, %{})
    end
  end

  def success(conn, _activity, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/"

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    |> assign(:current_user, user)
    |> put_flash(:info, "You are now signed in")
    |> redirect(to: return_to)
  end

  def failure(conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed. Please try again.")
    |> redirect(to: ~p"/sign-in")
  end

  def sign_out(conn, _params) do
    conn
    |> clear_session(:spazio_solazzo)
    |> put_flash(:info, "You are now signed out")
    |> redirect(to: ~p"/")
  end
end
