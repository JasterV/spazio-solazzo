defmodule SpazioSolazzoWeb.SignInLive do
  @moduledoc """
  Simple LiveView for requesting magic link sign-in emails.
  """

  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.Accounts

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:email, "")
      |> assign(:loading, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("request_magic_link", %{"email" => email}, socket) do
    socket = assign(socket, :loading, true)

    result = Accounts.request_magic_link(email, authorize?: false)

    case result do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Check your email for a sign-in link!")
         |> assign(:loading, false)
         |> assign(:email, "")}

      {:error, _error} ->
        # Note: Magic link strategy usually returns :ok even if email is missing 
        # to prevent user enumeration, but we handle the error case for safety.
        {:noreply,
         socket
         |> put_flash(:error, "Something went wrong. Please try again.")
         |> assign(:loading, false)}
    end
  end
end
