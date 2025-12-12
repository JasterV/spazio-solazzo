defmodule SpazioSolazzoWeb.MeetingLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.Space
      |> Ash.Changeset.for_create(:create, %{
        name: "MeetingTest",
        slug: "meeting",
        description: "desc"
      })
      |> Ash.create()

    {:ok, asset} =
      BookingSystem.Asset
      |> Ash.Changeset.for_create(:create, %{name: "Main Room", space_id: space.id})
      |> Ash.create()

    {:ok, slot} =
      BookingSystem.TimeSlotTemplate
      |> Ash.Changeset.for_create(:create, %{
        name: "Hour 1",
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        space_id: space.id
      })
      |> Ash.create()

    %{space: space, asset: asset, slot: slot}
  end

  test "meeting live shows time slots", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/meeting")

    html = render(view)
    assert String.contains?(html, "button") or String.contains?(html, "time-slot")
  end
end
