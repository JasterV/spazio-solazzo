defmodule SpazioSolazzoWeb.MeetingLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

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

    # Create slots for today
    today = Date.utc_today()
    day_of_week = day_of_week_atom(today)

    {:ok, slot} =
      BookingSystem.TimeSlotTemplate
      |> Ash.Changeset.for_create(:create, %{
        name: "9:00 - 10:00",
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        space_id: space.id,
        day_of_week: day_of_week
      })
      |> Ash.create()

    %{space: space, asset: asset, slot: slot}
  end

  defp day_of_week_atom(date) do
    case Date.day_of_week(date) do
      1 -> :monday
      2 -> :tuesday
      3 -> :wednesday
      4 -> :thursday
      5 -> :friday
      6 -> :saturday
      7 -> :sunday
    end
  end

  describe "MeetingLive" do
    test "renders meeting page with available time slots", %{conn: conn, space: space} do
      {:ok, _view, html} = live(conn, "/meeting")

      assert html =~ space.name
      assert html =~ "Available Time Slots"
    end

    test "displays time slots for selected date", %{conn: conn, slot: _slot} do
      {:ok, view, _html} = live(conn, "/meeting")

      assert has_element?(view, "button", "09:00 AM")
    end

    test "opens booking modal when clicking a time slot", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/meeting")

      view
      |> element("button[phx-click='select_slot']")
      |> render_click()

      assert has_element?(view, "#booking-modal")
      assert has_element?(view, "input[name='customer_name']")
      assert has_element?(view, "input[name='customer_email']")
    end

    test "completes full booking flow with email verification first", %{
      conn: conn,
      asset: asset,
      slot: slot
    } do
      # Submit form data to trigger email verification
      form_data = %{
        "customer_name" => "Test User",
        "customer_email" => "testuser@example.com"
      }

      {:ok, verification} =
        BookingSystem.EmailVerification
        |> Ash.Changeset.for_create(:create, %{email: form_data["customer_email"]})
        |> Ash.create()

      assert verification.email == "testuser@example.com"
      assert String.length(verification.code) == 6

      assert_email_sent(fn email_sent ->
        email_sent.to == [{"", "testuser@example.com"}] and
          email_sent.subject == "Verify your booking at Spazio Solazzo" and
          String.contains?(email_sent.html_body, verification.code)
      end)

      {:ok, _verified} =
        verification
        |> Ash.Changeset.for_update(:verify, %{code: verification.code})
        |> Ash.update()

      booking_params = %{
        asset_id: asset.id,
        time_slot_template_id: slot.id,
        date: Date.utc_today(),
        customer_name: form_data["customer_name"],
        customer_email: form_data["customer_email"]
      }

      {:ok, booking} =
        BookingSystem.Booking
        |> Ash.Changeset.for_create(:create, booking_params)
        |> Ash.create()

      assert booking.state == :reserved
      assert booking.customer_email == "testuser@example.com"

      assert {:error, _} = Ash.get(BookingSystem.EmailVerification, verification.id)
    end

    test "rejects booking with invalid email", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/meeting")

      view
      |> element("button[phx-click='select_slot']")
      |> render_click()

      view
      |> element("#booking-form")
      |> render_submit(%{
        "customer_name" => "Test User",
        "customer_email" => "invalid-email"
      })

      :timer.sleep(200)

      {:ok, bookings} = BookingSystem.Booking |> Ash.read()

      invalid_booking =
        Enum.find(bookings, fn b ->
          b.customer_email == "invalid-email"
        end)

      assert invalid_booking == nil, "Booking should not be created with invalid email"
    end

    test "rejects booking with empty name", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/meeting")

      view
      |> element("button[phx-click='select_slot']")
      |> render_click()

      view
      |> element("#booking-form")
      |> render_submit(%{
        "customer_name" => "",
        "customer_email" => "test@example.com"
      })

      :timer.sleep(200)

      {:ok, bookings} = BookingSystem.Booking |> Ash.read()

      empty_name_booking =
        Enum.find(bookings, fn b ->
          b.customer_name == ""
        end)

      assert empty_name_booking == nil, "Booking should not be created with empty name"
    end

    test "cancels booking flow", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/meeting")

      view
      |> element("button[phx-click='select_slot']")
      |> render_click()

      assert has_element?(view, "#booking-modal")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, "#booking-modal[data-show='true']")
    end
  end
end
