defmodule SpazioSolazzoWeb.PageLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem
  require Ash.Query

  def mount(_params, _session, socket) do
    {:ok, spaces} =
      BookingSystem.Space
      |> Ash.Query.filter(slug in ["coworking", "meeting", "music"])
      |> Ash.read()

    {:ok, assign(socket, spaces: spaces)}
  end
end
