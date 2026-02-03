defmodule SpazioSolazzoWeb.Admin.BookingManagementLive do
  @moduledoc """
  Admin booking management tool for reviewing and managing all booking requests.
  """

  use SpazioSolazzoWeb, :live_view

  import SpazioSolazzoWeb.Admin.BookingManagementComponents

  alias SpazioSolazzo.BookingSystem

  @pending_bookings_page_limit 10
  @booking_history_page_limit 10

  def mount(_params, _session, socket) do
    {:ok, spaces} = Ash.read(SpazioSolazzo.BookingSystem.Space)

    {:ok, pending_page} =
      BookingSystem.read_pending_bookings(nil, nil, nil,
        page: [limit: @pending_bookings_page_limit, offset: 0, count: true],
        load: [:space, :user]
      )

    {:ok, history_page} =
      BookingSystem.read_booking_history(nil, nil, nil,
        page: [limit: @booking_history_page_limit, offset: 0, count: true],
        load: [:space, :user]
      )

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:approved")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:cancelled")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:rejected")
    end

    {:ok,
     assign(socket,
       spaces: spaces,
       pending_page: pending_page,
       history_page: history_page,
       pending_page_number: 1,
       history_page_number: 1,
       filter_space_id: nil,
       filter_email: "",
       filter_date: nil,
       show_reject_modal: false,
       rejecting_booking_id: nil,
       rejection_reason: "",
       expanded_booking_ids: MapSet.new()
     )}
  end

  def handle_params(params, _uri, socket) do
    # Parse URL parameters - URL is the source of truth for all filters
    filter_space_id = if params["space_id"] == "" || is_nil(params["space_id"]), do: nil, else: params["space_id"]
    filter_email = params["email"] || ""
    filter_date = parse_date_param(params["date"])
    pending_page = parse_page_param(params["pending_page"])
    history_page = parse_page_param(params["history_page"])

    # Determine if we need to reload data
    needs_reload =
      params_changed?(
        socket.assigns.filter_space_id,
        filter_space_id,
        socket.assigns.filter_email,
        filter_email,
        socket.assigns.filter_date,
        filter_date,
        socket.assigns.pending_page_number,
        pending_page,
        socket.assigns.history_page_number,
        history_page
      )

    socket =
      if needs_reload do
        reload_bookings(socket, filter_space_id, filter_email, filter_date, pending_page, history_page)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("toggle_expand", %{"booking_id" => booking_id}, socket) do
    expanded =
      if MapSet.member?(socket.assigns.expanded_booking_ids, booking_id) do
        MapSet.delete(socket.assigns.expanded_booking_ids, booking_id)
      else
        MapSet.put(socket.assigns.expanded_booking_ids, booking_id)
      end

    {:noreply, assign(socket, expanded_booking_ids: expanded)}
  end

  def handle_event("filter_bookings", params, socket) do
    space_id = if params["space_id"] == "", do: nil, else: params["space_id"]
    email = if params["email"] == "", do: nil, else: params["email"]

    date =
      if params["date"] == "",
        do: nil,
        else: Date.from_iso8601!(params["date"])

    {:ok, pending_page} =
      BookingSystem.read_pending_bookings(space_id, email, date,
        page: [limit: @pending_bookings_page_limit, offset: 0, count: true],
        load: [:space, :user]
      )

    {:ok, history_page} =
      BookingSystem.read_booking_history(space_id, email, date,
        page: [limit: @booking_history_page_limit, offset: 0, count: true],
        load: [:space, :user]
      )

    updated_socket =
      assign(socket,
        pending_page: pending_page,
        history_page: history_page,
        pending_page_number: 1,
        history_page_number: 1,
        filter_space_id: space_id,
        filter_email: email || "",
        filter_date: date
      )

    {:noreply, push_patch(updated_socket, to: build_path(updated_socket, 1, 1))}
  end

  def handle_event("clear_filters", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/bookings")}
  end

  def handle_event("pending_page_change", %{"page" => page_str}, socket) do
    page_number = String.to_integer(page_str)

    socket =
      push_patch(socket,
        to: build_path(socket, page_number, socket.assigns.history_page_number)
      )

    {:noreply, socket}
  end

  def handle_event("history_page_change", %{"page" => page_str}, socket) do
    page_number = String.to_integer(page_str)

    socket =
      push_patch(socket,
        to: build_path(socket, socket.assigns.pending_page_number, page_number)
      )

    {:noreply, socket}
  end

  def handle_event("approve_booking", %{"booking_id" => booking_id}, socket) do
    case Ash.get(SpazioSolazzo.BookingSystem.Booking, booking_id) do
      {:ok, booking} ->
        case BookingSystem.approve_booking(booking) do
          {:ok, _approved} ->
            refresh_bookings(socket)

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to approve booking")}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Booking not found")}
    end
  end

  def handle_event("show_reject_modal", %{"booking_id" => booking_id}, socket) do
    {:noreply,
     assign(socket,
       show_reject_modal: true,
       rejecting_booking_id: booking_id,
       rejection_reason: ""
     )}
  end

  def handle_event("hide_reject_modal", _, socket) do
    {:noreply,
     assign(socket,
       show_reject_modal: false,
       rejecting_booking_id: nil,
       rejection_reason: ""
     )}
  end

  def handle_event("stop_propagation", _, socket) do
    {:noreply, socket}
  end

  def handle_event("update_rejection_reason", %{"reason" => reason}, socket) do
    {:noreply, assign(socket, rejection_reason: reason)}
  end

  def handle_event("confirm_reject", _, socket) do
    if String.trim(socket.assigns.rejection_reason) == "" do
      {:noreply, put_flash(socket, :error, "Please provide a rejection reason")}
    else
      case Ash.get(SpazioSolazzo.BookingSystem.Booking, socket.assigns.rejecting_booking_id) do
        {:ok, booking} ->
          case BookingSystem.reject_booking(booking, socket.assigns.rejection_reason) do
            {:ok, _rejected} ->
              socket =
                socket
                |> assign(
                  show_reject_modal: false,
                  rejecting_booking_id: nil,
                  rejection_reason: ""
                )
                |> put_flash(:info, "Booking rejected")

              refresh_bookings(socket)

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to reject booking")}
          end

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Booking not found")}
      end
    end
  end

  def handle_info(
        %{topic: "booking:" <> _event},
        socket
      ) do
    refresh_bookings(socket)
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp refresh_bookings(socket) do
    pending_page_number = socket.assigns.pending_page_number
    history_page_number = socket.assigns.history_page_number
    pending_offset = (pending_page_number - 1) * @pending_bookings_page_limit
    history_offset = (history_page_number - 1) * @booking_history_page_limit

    {:ok, pending_page} =
      BookingSystem.read_pending_bookings(
        socket.assigns.filter_space_id,
        socket.assigns.filter_email,
        socket.assigns.filter_date,
        page: [limit: @pending_bookings_page_limit, offset: pending_offset, count: true],
        load: [:space, :user]
      )

    {:ok, history_page} =
      BookingSystem.read_booking_history(
        socket.assigns.filter_space_id,
        socket.assigns.filter_email,
        socket.assigns.filter_date,
        page: [limit: @booking_history_page_limit, offset: history_offset, count: true],
        load: [:space, :user]
      )

    {:noreply,
     assign(socket,
       pending_page: pending_page,
       history_page: history_page
     )}
  end

  defp reload_bookings(socket, filter_space_id, filter_email, filter_date, pending_page_number, history_page_number) do
    pending_offset = (pending_page_number - 1) * @pending_bookings_page_limit
    history_offset = (history_page_number - 1) * @booking_history_page_limit

    email = if filter_email == "", do: nil, else: filter_email

    {:ok, pending_page} =
      BookingSystem.read_pending_bookings(filter_space_id, email, filter_date,
        page: [limit: @pending_bookings_page_limit, offset: pending_offset, count: true],
        load: [:space, :user]
      )

    {:ok, history_page} =
      BookingSystem.read_booking_history(filter_space_id, email, filter_date,
        page: [limit: @booking_history_page_limit, offset: history_offset, count: true],
        load: [:space, :user]
      )

    assign(socket,
      pending_page: pending_page,
      history_page: history_page,
      pending_page_number: pending_page_number,
      history_page_number: history_page_number,
      filter_space_id: filter_space_id,
      filter_email: filter_email,
      filter_date: filter_date
    )
  end

  defp build_path(socket, pending_page, history_page) do
    query_params = []

    query_params =
      if pending_page != 1,
        do: [{"pending_page", pending_page} | query_params],
        else: query_params

    query_params =
      if history_page != 1,
        do: [{"history_page", history_page} | query_params],
        else: query_params

    query_params =
      if socket.assigns.filter_space_id,
        do: [{"space_id", socket.assigns.filter_space_id} | query_params],
        else: query_params

    query_params =
      if socket.assigns.filter_email && socket.assigns.filter_email != "",
        do: [{"email", socket.assigns.filter_email} | query_params],
        else: query_params

    query_params =
      if socket.assigns.filter_date,
        do: [{"date", Date.to_iso8601(socket.assigns.filter_date)} | query_params],
        else: query_params

    base_path = ~p"/admin/bookings"

    if query_params == [] do
      base_path
    else
      query_string = URI.encode_query(query_params)
      "#{base_path}?#{query_string}"
    end
  end

  defp parse_date_param(nil), do: nil
  defp parse_date_param(""), do: nil

  defp parse_date_param(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp parse_page_param(nil), do: 1
  defp parse_page_param(""), do: 1

  defp parse_page_param(page_string) do
    case Integer.parse(page_string) do
      {page, _} when page > 0 -> page
      _ -> 1
    end
  end

  defp params_changed?(old_space_id, new_space_id, old_email, new_email, old_date, new_date, old_pending, new_pending, old_history, new_history) do
    old_space_id != new_space_id or old_email != new_email or old_date != new_date or old_pending != new_pending or old_history != new_history
  end
end
