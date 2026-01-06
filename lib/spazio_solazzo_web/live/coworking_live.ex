defmodule SpazioSolazzoWeb.CoworkingLive do
  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    {:ok, space} = BookingSystem.get_space_by_slug("coworking")
    {:ok, assets} = BookingSystem.get_space_assets(space.id)

    {:ok,
     socket
     |> assign(
       space: space,
       assets: assets
     )}
  end
end
