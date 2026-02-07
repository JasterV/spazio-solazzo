defmodule SpazioSolazzoWeb.PageLive do
  use SpazioSolazzoWeb, :live_view

  import SpazioSolazzoWeb.PageComponents
  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    {:ok, coworking_space} =
      BookingSystem.get_space_by_slug("arcipelago", not_found_error?: false)

    {:ok, meeting_space} = BookingSystem.get_space_by_slug("media-room", not_found_error?: false)
    {:ok, music_space} = BookingSystem.get_space_by_slug("hall", not_found_error?: false)

    carousel_images = [
      ~p"/images/extra/outside-02.jpg",
      ~p"/images/music_room/03.jpg",
      ~p"/images/extra/chillout.jpg",
      ~p"/images/meeting_room/02.jpg",
      ~p"/images/music_room/01.jpg",
      ~p"/images/coworking_room/01.jpg"
    ]

    {:ok,
     assign(socket,
       coworking_space: coworking_space,
       meeting_space: meeting_space,
       music_space: music_space,
       carousel_images: carousel_images
     )}
  end
end
