defmodule SpazioSolazzoWeb.AuthCallbackLive do
  @moduledoc """
  Handles magic link callbacks for authentication.
  Shows registration form for new users, sign-in confirmation for existing users.
  """

  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.Accounts
  alias SpazioSolazzo.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:email, nil)
      |> assign(:existing_user?, false)
      |> assign(:token, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    token = params["token"]

    socket =
      case token do
        nil ->
          socket
          |> put_flash(:error, "Missing token parameter")
          |> push_navigate(to: ~p"/sign-in")

        token ->
          process_magic_link(socket, token)
      end

    {:noreply, socket}
  end

  defp process_magic_link(socket, token) do
    case extract_email_from_token(token) do
      {:ok, email} ->
        existing_user? =
          case Accounts.get_user_by_email(email, authorize?: false) do
            {:ok, user} when not is_nil(user) -> true
            _ -> false
          end

        socket
        |> assign(:token, token)
        |> assign(:email, email)
        |> assign(:existing_user?, existing_user?)

      {:error, _reason} ->
        socket
        |> put_flash(:error, "Invalid or expired magic link")
        |> push_navigate(to: ~p"/sign-in")
    end
  end

  @impl true
  def handle_event("sign_in", args, %{assigns: %{token: token}} = socket) do
    remember_me = Map.get(args, "remember_me") == "on"
    params = %{"token" => token, "remember_me" => remember_me}
    sign_in(socket, params)
  end

  @impl true
  def handle_event(
        "register",
        %{"name" => name, "phone_number" => phone_number} = args,
        socket
      ) do
    %{token: token} = socket.assigns
    remember_me = Map.get(args, "remember_me") == "on"

    params = %{
      "token" => token,
      "name" => name,
      "phone_number" => phone_number,
      "remember_me" => remember_me
    }

    sign_in(socket, params)
  end

  defp sign_in(socket, params) do
    case User
         |> Ash.Changeset.for_create(:sign_in_with_magic_link, params)
         |> Ash.create(authorize?: false) do
      {:ok, user} ->
        {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
        {:noreply, redirect(socket, to: ~p"/auth/callback?token=#{token}")}

      {:error, _} ->
        {:noreply, redirect(socket, to: ~p"/auth/failure")}
    end
  end

  defp extract_email_from_token(token) do
    case AshAuthentication.Jwt.peek(token) do
      {:ok, %{"identity" => email}} ->
        {:ok, email}

      {:error, _} = error ->
        error
    end
  end
end
