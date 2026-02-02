defmodule SpazioSolazzoWeb.MusicLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} = BookingSystem.create_space("MusicTest", "music", "desc", 1)

    %{space: space}
  end

  describe "MusicLive landing page" do
    test "renders music landing page with space information", %{
      conn: conn,
      space: space
    } do
      {:ok, _view, html} = live(conn, "/music")

      assert html =~ space.name
    end

    test "has link to space booking page with correct space slug", %{conn: conn, space: space} do
      {:ok, view, _html} = live(conn, "/music")

      assert has_element?(view, "a[href='/book/space/#{space.slug}']")
    end
  end
end
