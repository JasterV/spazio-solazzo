defmodule SpazioSolazzoWeb.Admin.DashboardLive do
  @moduledoc """
  Admin dashboard home page. Lists the available tools that admins have
  """

  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem
  import SpazioSolazzoWeb.AdminComponents

  def mount(_params, _session, socket) do
    {:ok, coworking_space} = BookingSystem.get_space_by_slug("coworking", not_found_error?: false)
    {:ok, meeting_space} = BookingSystem.get_space_by_slug("meeting", not_found_error?: false)

    {:ok,
     assign(socket,
       coworking_space: coworking_space,
       meeting_space: meeting_space
     )}
  end
end
