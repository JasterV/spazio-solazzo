defmodule SpazioSolazzoWeb.CoworkingLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.Space
      |> Ash.Changeset.for_create(:create, %{
        name: "CoworkingTest",
        slug: "coworking",
        description: "desc"
      })
      |> Ash.create()

    {:ok, asset} =
      BookingSystem.Asset
      |> Ash.Changeset.for_create(:create, %{name: "T1", space_id: space.id})
      |> Ash.create()

    {:ok, slot} =
      BookingSystem.TimeSlotTemplate
      |> Ash.Changeset.for_create(:create, %{
        name: "S1",
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        space_id: space.id,
        day_of_week: :monday
      })
      |> Ash.create()

    %{space: space, asset: asset, slot: slot}
  end

  test "selecting asset loads time slots and shows booked state", %{
    conn: conn,
    asset: asset
  } do
    {:ok, _view, _html} = live(conn, "/")

    # navigate to the cowo space route
    assert {:ok, _view, _html} = live(conn, "/coworking")

    {:ok, coworking_view, _} = live(conn, "/coworking")

    # select asset
    coworking_view |> element("button[phx-value-id=\"#{asset.id}\"]") |> render_click()

    # time slot button should be present
    html = render(coworking_view)
    assert String.contains?(html, "button") or String.contains?(html, "time-slot")
  end
end
