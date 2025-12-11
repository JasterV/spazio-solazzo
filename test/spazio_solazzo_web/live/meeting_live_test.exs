defmodule SpazioSolazzoWeb.MeetingLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} = BookingSystem.create_space("MeetingTest", "meeting", "desc")
    {:ok, asset} = BookingSystem.create_asset("Main Room", space.id)

    %{space: space, asset: asset}
  end

  describe "MeetingLive landing page" do
    test "renders meeting landing page with space information", %{
      conn: conn,
      space: space
    } do
      {:ok, view, html} = live(conn, "/meeting")

      assert html =~ space.name
      assert html =~ "Book This Room"
      assert has_element?(view, "h2", "Everything you need to succeed")
    end

    test "has link to asset booking page with correct asset id", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, "/meeting")

      assert has_element?(view, "a[href='/book/asset/#{asset.id}']", "Book This Room")
    end
  end
end
