defmodule SpazioSolazzoWeb.Admin.BookingManagementLive do
  @moduledoc """
  Admin booking management tool for reviewing and managing all booking requests.
  """

  use SpazioSolazzoWeb, :live_view

  alias SpazioSolazzo.BookingSystem

  def mount(_params, _session, socket) do
    {:ok, spaces} = Ash.read(SpazioSolazzo.BookingSystem.Space)
    {:ok, bookings} = BookingSystem.list_booking_requests(nil, nil, nil, load: [:space, :user])

    # Separate pending and other bookings
    {pending, past} = Enum.split_with(bookings, &(&1.state == :requested))

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:created")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:approved")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:cancelled")
      Phoenix.PubSub.subscribe(SpazioSolazzo.PubSub, "booking:rejected")
    end

    {:ok,
     assign(socket,
       spaces: spaces,
       pending_bookings: pending,
       past_bookings: past,
       filter_space_id: nil,
       filter_email: "",
       filter_date: nil,
       show_reject_modal: false,
       rejecting_booking_id: nil,
       rejection_reason: "",
       expanded_booking_ids: MapSet.new()
     )}
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

    {:ok, bookings} =
      BookingSystem.list_booking_requests(space_id, email, date, load: [:space, :user])

    {pending, past} = Enum.split_with(bookings, &(&1.state == :requested))

    {:noreply,
     assign(socket,
       pending_bookings: pending,
       past_bookings: past,
       filter_space_id: space_id,
       filter_email: email || "",
       filter_date: date
     )}
  end

  def handle_event("clear_filters", _, socket) do
    {:ok, bookings} = BookingSystem.list_booking_requests(nil, nil, nil, load: [:space, :user])
    {pending, past} = Enum.split_with(bookings, &(&1.state == :requested))

    {:noreply,
     assign(socket,
       pending_bookings: pending,
       past_bookings: past,
       filter_space_id: nil,
       filter_email: "",
       filter_date: nil
     )}
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
    {:ok, bookings} =
      BookingSystem.list_booking_requests(
        socket.assigns.filter_space_id,
        socket.assigns.filter_email,
        socket.assigns.filter_date,
        load: [:space, :user]
      )

    {pending, past} = Enum.split_with(bookings, &(&1.state == :requested))

    {:noreply,
     assign(socket,
       pending_bookings: pending,
       past_bookings: past
     )}
  end

  defp status_badge_classes(:requested) do
    "bg-amber-100 dark:bg-amber-900/40 text-amber-800 dark:text-amber-200"
  end

  defp status_badge_classes(:accepted) do
    "bg-green-100 dark:bg-green-900/40 text-green-800 dark:text-green-200"
  end

  defp status_badge_classes(:rejected) do
    "bg-red-100 dark:bg-red-900/40 text-red-800 dark:text-red-200"
  end

  defp status_badge_classes(:cancelled) do
    "bg-slate-100 dark:bg-slate-900/40 text-slate-800 dark:text-slate-200"
  end

  defp status_badge_classes(_), do: "bg-slate-100 text-slate-800"

  defp status_icon(:requested), do: "hero-clock"
  defp status_icon(:accepted), do: "hero-check-circle"
  defp status_icon(:rejected), do: "hero-x-circle"
  defp status_icon(:cancelled), do: "hero-minus-circle"
  defp status_icon(_), do: "hero-question-mark-circle"

  defp status_label(:requested), do: "Pending"
  defp status_label(:accepted), do: "Confirmed"
  defp status_label(:rejected), do: "Rejected"
  defp status_label(:cancelled), do: "Cancelled"
  defp status_label(_), do: "Unknown"
end
