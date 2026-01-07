defmodule SpazioSolazzoWeb.BookingLive.AssetBookingTest do
  use SpazioSolazzoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SpazioSolazzo.BookingSystem

  setup do
    {:ok, space} = BookingSystem.create_space("TestSpace", "test-space", "Test description")
    {:ok, asset} = BookingSystem.create_asset("Test Asset", space.id)

    today = Date.utc_today()
    day_of_week = SpazioSolazzo.DateExt.day_of_week_atom(today)

    {:ok, slot} =
      BookingSystem.create_time_slot_template(
        ~T[09:00:00],
        ~T[10:00:00],
        day_of_week,
        space.id
      )

    %{space: space, asset: asset, slot: slot}
  end

  describe "AssetBooking mount" do
    test "renders asset booking page with available time slots", %{
      conn: conn,
      space: space,
      asset: asset
    } do
      {:ok, view, html} = live(conn, ~p"/book/asset/#{asset.id}")

      assert html =~ space.name
      assert html =~ asset.name
      assert html =~ "Available Time Slots"
      assert has_element?(view, "button", "09:00 AM")
    end

    test "redirects when asset not found", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/", flash: %{"error" => "Asset not found"}}}} =
               live(conn, ~p"/book/asset/00000000-0000-0000-0000-000000000000")
    end
  end

  describe "AssetBooking time slot selection" do
    test "opens booking modal when clicking a time slot", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

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
  end

  describe "AssetBooking full booking flow" do
    test "completes full booking flow with email verification", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

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

      assert has_element?(view, "#email-verification-modal")

      Oban.drain_queue(queue: :email_verification)

      assert %Swoosh.Email{
               subject: subject,
               html_body: html_body,
               to: sent_to
             } = pop_email()

      assert sent_to == [{"", form_data["customer_email"]}]
      assert subject == "Verify your booking at Spazio Solazzo"

      [_, extracted_code] = Regex.run(~r/code-text">(\d{6})</, html_body)

      view
      |> element("#otp-form-email-verification-modal")
      |> render_submit(%{"code" => extracted_code})

      assert has_element?(view, "#success-modal")

      assert {:ok, [booking]} =
               BookingSystem.list_active_asset_bookings_by_date(asset.id, Date.utc_today())

      assert booking.customer_email == form_data["customer_email"]
      assert booking.customer_phone == "+39 35273464176"
    end
  end

  describe "AssetBooking validation" do
    test "rejects booking with invalid email", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

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

    test "rejects booking with empty name", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

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

    test "rejects booking with invalid phone number", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

      view
      |> element("button[phx-click='select_slot']")
      |> render_click()

      view
      |> element("#booking-form")
      |> render_submit(%{
        "customer_name" => "Test User",
        "customer_email" => "test@example.com",
        "phone_prefix" => "+39",
        "phone_number" => "invalid",
        "customer_comment" => "test comment"
      })

      assert view |> has_element?("#booking-form")
    end
  end

  describe "AssetBooking cancellation" do
    test "cancels booking flow", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

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

  describe "AssetBooking date selection" do
    test "updates available time slots when changing date", %{
      conn: conn,
      asset: asset,
      space: space
    } do
      {:ok, view, _html} = live(conn, ~p"/book/asset/#{asset.id}")

      tomorrow = Date.add(Date.utc_today(), 1)
      tomorrow_day_of_week = SpazioSolazzo.DateExt.day_of_week_atom(tomorrow)

      {:ok, _slot} =
        BookingSystem.create_time_slot_template(
          ~T[14:00:00],
          ~T[15:00:00],
          tomorrow_day_of_week,
          space.id
        )

      view
      |> element("form[phx-change='change_date']")
      |> render_change(%{"date" => Date.to_string(tomorrow)})

      assert has_element?(view, "button", "02:00 PM")
    end
  end
end
