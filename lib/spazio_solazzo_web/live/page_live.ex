defmodule SpazioSolazzoWeb.PageLive do
  use SpazioSolazzoWeb, :live_view

  import SpazioSolazzoWeb.PageComponents
  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    {:ok, coworking_space} = BookingSystem.get_space_by_slug("coworking")
    {:ok, meeting_space} = BookingSystem.get_space_by_slug("meeting")
    {:ok, music_space} = BookingSystem.get_space_by_slug("music")

    {:ok,
     assign(socket,
       coworking_space: coworking_space,
       meeting_space: meeting_space,
       music_space: music_space
     )}
  end
end
