defmodule SpazioSolazzoWeb.Admin.DashboardLive do
  @moduledoc """
  Admin dashboard home page showing available management tools.
  """

  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    # Get pending requests count for the badge
    {:ok, pending_requests} = BookingSystem.count_pending_requests()
    pending_count = length(pending_requests)

    {:ok,
     assign(socket,
       pending_requests_count: pending_count
     )}
  end
end
