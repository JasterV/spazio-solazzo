defmodule SpazioSolazzoWeb.PageLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    for {name, slug} <- [{"Coworking", "coworking"}, {"Meeting", "meeting"}, {"Music", "music"}] do
      BookingSystem.create_space!(name, slug, "desc", 10, 12)
    end

    :ok
  end

  test "homepage shows three space cards", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html = render(view)

    assert String.contains?(html, "/coworking")
    assert String.contains?(html, "/meeting")
    assert String.contains?(html, "/music")
  end
end
