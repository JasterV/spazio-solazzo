defmodule SpazioSolazzoWeb.MusicLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.Space
      |> Ash.Changeset.for_create(:create, %{
        name: "MusicTest",
        slug: "music",
        description: "desc"
      })
      |> Ash.create()

    {:ok, asset} =
      BookingSystem.Asset
      |> Ash.Changeset.for_create(:create, %{name: "Studio", space_id: space.id})
      |> Ash.create()

    {:ok, slot} =
      BookingSystem.TimeSlotTemplate
      |> Ash.Changeset.for_create(:create, %{
        name: "Evening",
        start_time: ~T[18:00:00],
        end_time: ~T[20:00:00],
        space_id: space.id,
        day_of_week: :monday
      })
      |> Ash.create()

    %{space: space, asset: asset, slot: slot}
  end

  test "music live shows time slots", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/music")

    html = render(view)
    assert String.contains?(html, "button") or String.contains?(html, "time-slot")
  end
end
