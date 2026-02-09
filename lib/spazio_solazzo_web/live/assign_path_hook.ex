defmodule SpazioSolazzoWeb.AssignPathHook do
  @moduledoc """
  Attach a `handle_params` hook on any live view that injects the current path from the URL into the socket assigns
  """

  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :set_current_path, :handle_params, &handle_path_update/3)}
  end

  defp handle_path_update(_params, url, socket) do
    %{path: path} = URI.parse(url)
    {:cont, assign(socket, :current_path, path)}
  end
end
