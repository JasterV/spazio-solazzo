defmodule SpazioSolazzoWeb.Admin.DashboardLive do
  @moduledoc """
  Admin dashboard home page showing available management tools.
  """

  use SpazioSolazzoWeb, :live_view

  import SpazioSolazzoWeb.AdminDashboardComponents

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
