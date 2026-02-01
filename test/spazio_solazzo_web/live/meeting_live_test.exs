defmodule SpazioSolazzoWeb.MeetingLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} = BookingSystem.create_space("MeetingTest", "meeting", "desc", 1, 1)

    %{space: space}
  end

  describe "MeetingLive landing page" do
    test "renders meeting landing page with space information", %{
      conn: conn,
      space: space
    } do
      {:ok, _view, html} = live(conn, "/meeting")

      assert html =~ space.name
    end

    test "has link to space booking page with correct space slug", %{conn: conn, space: space} do
      {:ok, view, _html} = live(conn, "/meeting")

      assert has_element?(view, "a[href='/book/space/#{space.slug}']")
    end
  end
end
