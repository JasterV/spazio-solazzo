defmodule SpazioSolazzoWeb.BookingComponents do
  @moduledoc """
  Reusable components for the booking flow.
  """
  use Phoenix.Component

  import SpazioSolazzoWeb.CoreComponents, only: [icon: 1]

  attr :time_slot, :map, required: true

  @doc """
  Renders a detailed time slot card showing availability status and booking counts.
  """
  def time_slot_card(assigns) do
    assigns =
      assigns
      |> assign(:availability, assigns.time_slot.booking_stats.availability_status)
      |> assign(:requested_count, assigns.time_slot.booking_stats.requested_count)
      |> assign(:accepted_count, assigns.time_slot.booking_stats.accepted_count)
      |> assign(:user_has_booking, assigns.time_slot.booking_stats.user_has_booking)

    ~H"""
    <button
      phx-click={if @user_has_booking, do: nil, else: "select_slot"}
      phx-value-time_slot_id={@time_slot.id}
      disabled={@user_has_booking}
      class={[
        "w-full p-4 rounded-xl border-2 transition-all duration-200 text-left",
        if(@user_has_booking,
          do:
            "border-slate-200 bg-slate-100 cursor-not-allowed opacity-60 dark:bg-slate-700/50 dark:border-slate-600",
          else:
            if(@availability == :available,
              do:
                "border-green-200 bg-green-50 hover:border-green-500 hover:shadow-lg cursor-pointer dark:bg-green-900/20 dark:border-green-800 dark:hover:border-green-600",
              else:
                "border-yellow-200 bg-yellow-50 hover:border-yellow-500 hover:shadow-lg cursor-pointer dark:bg-yellow-900/20 dark:border-yellow-800 dark:hover:border-yellow-600"
            )
        )
      ]}
    >
      <div class="flex items-center justify-between">
        <div class="flex-1">
          <div class="text-lg font-semibold text-slate-900 dark:text-white">
            {Calendar.strftime(@time_slot.start_time, "%H:%M")} - {Calendar.strftime(
              @time_slot.end_time,
              "%H:%M"
            )}
          </div>
          <%= if @user_has_booking do %>
            <div class="text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
              Already Requested
            </div>
          <% else %>
            <%= if @availability == :available do %>
              <div class="text-sm text-green-600 dark:text-green-400 font-medium mt-1">
                Available - Request Booking
              </div>
            <% else %>
              <div class="text-sm text-yellow-600 dark:text-yellow-400 font-medium mt-1">
                High Demand - Join Waitlist
              </div>
            <% end %>
          <% end %>
          <div class="flex gap-3 mt-2 text-xs text-slate-600 dark:text-slate-400">
            <%= if @requested_count > 0 do %>
              <span class="flex items-center gap-1">
                <.icon name="hero-clock" class="w-3.5 h-3.5" />
                {@requested_count} pending
              </span>
            <% end %>
            <%= if @accepted_count > 0 do %>
              <span class="flex items-center gap-1">
                <.icon name="hero-check-circle" class="w-3.5 h-3.5" />
                {@accepted_count} booked
              </span>
            <% end %>
          </div>
        </div>
        <.icon
          name={if @user_has_booking, do: "hero-check", else: "hero-arrow-right"}
          class={[
            "w-5 h-5",
            if(@user_has_booking,
              do: "text-slate-400 dark:text-slate-500",
              else:
                if(@availability == :available,
                  do: "text-green-500 dark:text-green-400",
                  else: "text-yellow-500 dark:text-yellow-400"
                )
            )
          ]}
        />
      </div>
    </button>
    """
  end
end
