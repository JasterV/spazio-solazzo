defmodule SpazioSolazzoWeb.CoworkingLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} = BookingSystem.create_space("CoworkingTest", "coworking", "desc")
    {:ok, asset1} = BookingSystem.create_asset("Table 1", space.id)
    {:ok, asset2} = BookingSystem.create_asset("Table 2", space.id)

    %{space: space, assets: [asset1, asset2]}
  end

  describe "CoworkingLive landing page" do
    test "renders coworking landing page with space information", %{conn: conn, space: space} do
      {:ok, _view, html} = live(conn, "/coworking")

      assert html =~ space.name
      assert html =~ "Interactive Floor Plan"
      assert html =~ "Fiber Internet"
    end

    test "displays all available assets as selectable cards", %{
      conn: conn,
      assets: [asset1, asset2]
    } do
      {:ok, view, html} = live(conn, "/coworking")

      assert html =~ asset1.name
      assert html =~ asset2.name

      assert has_element?(view, "a[href='/book/asset/#{asset1.id}']")
      assert has_element?(view, "a[href='/book/asset/#{asset2.id}']")
    end
  end
end
