defmodule SpazioSolazzoWeb.MusicLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem
  # Landing page components
  import SpazioSolazzoWeb.LandingComponents

  def mount(_params, _session, socket) do
    {:ok, space} = BookingSystem.get_space_by_slug("music")

    {:ok, assign(socket, space: space)}
  end
end
