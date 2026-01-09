defmodule SpazioSolazzoWeb.ProfileLive do
  use SpazioSolazzoWeb, :live_view

  alias AshPhoenix.Form
  alias SpazioSolazzo.Accounts

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    profile_form =
      Accounts.form_to_update_profile(current_user, actor: current_user)
      |> to_form()

    {:ok,
     socket
     |> assign(:profile_form, profile_form)
     |> assign(:delete_history, false)
     |> assign(:show_delete_modal, false)}
  end

  def handle_event("validate_profile", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.profile_form, params)
    {:noreply, assign(socket, :profile_form, form)}
  end

  def handle_event("save_profile", %{"form" => form_params}, socket) do
    case Form.submit(socket.assigns.profile_form, params: form_params) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:profile_form, to_form(form_params))
         |> put_flash(:info, "Profile updated successfully")}

      {:error, form} ->
        {:noreply,
         socket
         |> assign(:profile_form, form)
         |> put_flash(:error, "Something went wrong")}
    end
  end

  def handle_event("toggle_delete_history", _params, socket) do
    {:noreply, assign(socket, :delete_history, not socket.assigns.delete_history)}
  end

  def handle_event("show_delete_modal", _params, socket) do
    {:noreply, assign(socket, :show_delete_modal, true)}
  end

  def handle_event("hide_delete_modal", _params, socket) do
    {:noreply, assign(socket, :show_delete_modal, false)}
  end

  def handle_event(
        "confirm_delete_account",
        _params,
        %{assigns: %{current_user: current_user, delete_history: delete_history}} = socket
      ) do
    case Accounts.terminate_account(current_user, delete_history, actor: current_user) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Your account has been deleted")
         |> redirect(to: "/sign-out")}

      {:error, _error} ->
        {:noreply,
         socket
         |> assign(:show_delete_modal, false)
         |> put_flash(:error, "Failed to delete account. Please try again.")}
    end
  end
end
