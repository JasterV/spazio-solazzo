defmodule SpazioSolazzoWeb.MusicLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} = BookingSystem.create_space("MusicTest", "music", "desc")
    {:ok, asset} = BookingSystem.create_asset("Studio", space.id)

    %{space: space, asset: asset}
  end

  describe "MusicLive landing page" do
    test "renders music landing page with space information", %{
      conn: conn,
      space: space,
      asset: asset
    } do
      {:ok, view, html} = live(conn, "/music")

      assert html =~ space.name
      assert html =~ asset.name
      assert html =~ "Book This Room"
      assert has_element?(view, "h3", "Features & Equipment")
    end

    test "has link to asset booking page with correct asset id", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, "/music")

      assert has_element?(view, "a[href='/book/asset/#{asset.id}']", "Book This Room")
    end
  end
end
