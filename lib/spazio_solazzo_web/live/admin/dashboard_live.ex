defmodule SpazioSolazzoWeb.Admin.DashboardLive do
  @moduledoc """
  Admin dashboard home page showing available management tools.
  """

  use SpazioSolazzoWeb, :live_view

  def mount(_params, _session, socket) do
    # Get pending requests count directly from database (no data loaded)
    {:ok, pending_count} =
      Ash.count(SpazioSolazzo.BookingSystem.Booking,
        query: [filter: [state: :requested]]
      )

    {:ok,
     assign(socket,
       pending_requests_count: pending_count
     )}
  end
end
