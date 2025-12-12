defmodule SpazioSolazzoWeb.PageLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    for {name, slug} <- [{"Coworking", "coworking"}, {"Meeting", "meeting"}, {"Music", "music"}] do
      {:ok, _} =
        BookingSystem.Space
        |> Ash.Changeset.for_create(:create, %{name: name, slug: slug, description: "desc"})
        |> Ash.create()
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
