defmodule SpazioSolazzoWeb.MeetingLiveTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} = BookingSystem.create_space("MeetingTest", "meeting", "desc")
    {:ok, asset} = BookingSystem.create_asset("Main Room", space.id)

    # Create slots for today
    today = Date.utc_today()
    day_of_week = SpazioSolazzo.DateExt.day_of_week_atom(today)

    {:ok, slot} =
      BookingSystem.create_time_slot_template(
        "9:00 - 10:00",
        ~T[09:00:00],
        ~T[10:00:00],
        day_of_week,
        space.id
      )

    %{space: space, asset: asset, slot: slot}
  end

  describe "MeetingLive" do
    test "renders meeting page with available time slots", %{conn: conn, space: space} do
      {:ok, view, html} = live(conn, "/meeting")

      assert html =~ space.name
      assert html =~ "Available Time Slots"
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
      assert has_element?(view, "input[name='phone_number']")
      assert has_element?(view, "input[name='phone_prefix']")
      assert has_element?(view, "textarea[name='customer_comment']")
    end

    test "completes full booking flow with email verification first", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, "/meeting")

      # Open booking modal by selecting an available time slot
      view
      |> element("button[phx-click='select_slot']")
      |> render_click()

      assert has_element?(view, "#booking-modal")

      form_data = %{
        "customer_name" => "Test User",
        "customer_email" => "testuser@example.com",
        "phone_prefix" => "+39",
        "phone_number" => "35273464176",
        "customer_comment" => "test comment"
      }

      # Fill the form (trigger change) then submit to simulate user input
      view
      |> element("#booking-form")
      |> render_change(%{
        "customer_name" => form_data["customer_name"],
        "customer_email" => form_data["customer_email"],
        "phone_prefix" => form_data["phone_prefix"],
        "phone_number" => form_data["phone_number"],
        "customer_comment" => form_data["customer_comment"]
      })

      view
      |> element("#booking-form")
      |> render_submit(%{})

      # After submitting the booking form the email verification modal should be shown
      assert has_element?(view, "#email-verification-modal")

      # Force jobs to execute
      Oban.drain_queue(queue: :email_verification)

      # Wait a short while for the email to be sent and then read it from Local storage
      assert %Swoosh.Email{
               subject: subject,
               html_body: html_body,
               to: sent_to
             } = Swoosh.Adapters.Local.Storage.Memory.pop()

      assert sent_to == [{"", form_data["customer_email"]}]
      assert subject == "Verify your booking at Spazio Solazzo"

      # Extract the 6-digit code from the email body
      [_, extracted_code] = Regex.run(~r/code-text">(\d{6})</, html_body)

      # Submit the verification code via the verification modal form
      view
      |> element("#otp-form-email-verification-modal")
      |> render_submit(%{"code" => extracted_code})

      # Success modal should be visible after successful verification & booking creation
      assert has_element?(view, "#success-modal")

      # Verify booking exists for the asset on the selected date
      assert {:ok, [booking]} =
               BookingSystem.list_active_asset_bookings_by_date(asset.id, Date.utc_today())

      assert booking.customer_email == form_data["customer_email"]
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
        "customer_email" => "invalid-email",
        "phone_prefix" => "+39",
        "phone_number" => "35273464176",
        "customer_comment" => "test comment"
      })

      assert view |> has_element?("#booking-form")
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
        "customer_email" => "test@example.com",
        "phone_prefix" => "+39",
        "phone_number" => "35273464176",
        "customer_comment" => "test comment"
      })

      assert view |> has_element?("#booking-form")
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

      refute has_element?(view, "#booking-form")
    end
  end
end
