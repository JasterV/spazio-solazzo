defmodule SpazioSolazzoWeb.MeetingLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    {:ok, space} = BookingSystem.get_space_by_slug("meeting")

    {:ok, assign(socket, space: space)}
  end
end
