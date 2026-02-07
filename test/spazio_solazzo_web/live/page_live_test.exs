defmodule SpazioSolazzoWeb.PageLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    for {name, slug} <- [{"Arcipelago", "arcipelago"}, {"Media Room", "media-room"}, {"Hall", "hall"}] do
      BookingSystem.create_space!(name, slug, "desc", 10)
    end

    :ok
  end

  test "homepage shows three space cards", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html = render(view)

    assert String.contains?(html, "/arcipelago")
    assert String.contains?(html, "/media-room")
    assert String.contains?(html, "/hall")
  end
end
