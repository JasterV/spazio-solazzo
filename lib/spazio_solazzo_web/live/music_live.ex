defmodule SpazioSolazzoWeb.MusicLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    {:ok, space} = BookingSystem.get_space_by_slug("music")
    {:ok, asset} = BookingSystem.get_asset_by_space_id(space.id)

    {:ok,
     socket
     |> assign(
       space: space,
       asset: asset
     )}
  end
end
