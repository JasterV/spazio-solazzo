defmodule SpazioSolazzo.BookingSystem.BookingTest do
  use ExUnit.Case
  use SpazioSolazzo.DataCase

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} =
      BookingSystem.Space
      |> Ash.Changeset.for_create(:create, %{name: "Test", slug: "test2", description: "desc"})
      |> Ash.create()

    {:ok, asset} =
      BookingSystem.Asset
      |> Ash.Changeset.for_create(:create, %{name: "Table 1", space_id: space.id})
      |> Ash.create()

    {:ok, template} =
      BookingSystem.TimeSlotTemplate
      |> Ash.Changeset.for_create(:create, %{
        name: "Full Day",
        start_time: ~T[09:00:00],
        end_time: ~T[18:00:00],
        space_id: space.id,
        day_of_week: :monday
      })
      |> Ash.create()

    %{space: space, asset: asset, template: template}
  end

  test "creates a booking with template times", %{asset: asset, template: template} do
    params = %{
      asset_id: asset.id,
      time_slot_template_id: template.id,
      date: Date.utc_today(),
      customer_name: "John",
      customer_email: "john@example.com"
    }

    {:ok, booking} =
      BookingSystem.Booking
      |> Ash.Changeset.for_create(:create, params)
      |> Ash.create()

    assert booking.start_time == template.start_time
    assert booking.end_time == template.end_time
  end
end
