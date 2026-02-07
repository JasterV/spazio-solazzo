defmodule SpazioSolazzoWeb.CoworkingLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} = BookingSystem.create_space("ArcipelagoTest", "arcipelago", "desc", 10)

    %{space: space}
  end

  describe "CoworkingLive landing page" do
    test "renders coworking landing page with space information", %{conn: conn, space: space} do
      {:ok, _view, html} = live(conn, "/arcipelago")

      assert html =~ space.name
      assert html =~ "Fiber Internet"
    end

    test "has link to space booking page with correct space slug", %{conn: conn, space: space} do
      {:ok, view, _html} = live(conn, "/arcipelago")

      assert has_element?(view, "a[href='/book/space/#{space.slug}']")
    end
  end
end
