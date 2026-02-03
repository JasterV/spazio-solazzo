defmodule SpazioSolazzoWeb.Admin.BookingManagementComponents do
  @moduledoc """
  Reusable components for the admin booking management interface.
  """
  use Phoenix.Component
  import SpazioSolazzoWeb.CoreComponents

  attr :title, :string, required: true
  attr :bookings, :list, required: true
  attr :page, :map, required: true
  attr :current_page, :integer, required: true
  attr :event_prefix, :string, required: true
  attr :expanded_booking_ids, :any, required: true
  attr :show_actions, :boolean, default: false
  attr :show_cancellation_details, :boolean, default: false

  def bookings_table(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-bold text-slate-900 dark:text-white mb-4">{@title}</h2>
      <div class="bg-white dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200 dark:divide-slate-700">
            <thead class="bg-slate-50 dark:bg-slate-900">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider w-[4%]">
                </th>
                <th class="px-6 py-3 text-left text-xs font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider">
                  Space
                </th>
                <th class="px-6 py-3 text-left text-xs font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider">
                  Start
                </th>
                <th class="px-6 py-3 text-left text-xs font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider">
                  End
                </th>
                <th class="px-6 py-3 text-left text-xs font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider">
                  Customer
                </th>
                <th class="px-6 py-3 text-left text-xs font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider">
                  Status
                </th>
                <%= if @show_actions do %>
                  <th class="px-6 py-3 text-center text-xs font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider min-w-[240px]">
                    Actions
                  </th>
                <% end %>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-200 dark:divide-slate-700">
              <%= for booking <- @bookings do %>
                <% is_expanded = MapSet.member?(@expanded_booking_ids, booking.id) %>
                <tr class={["group", if(is_expanded, do: "expanded", else: "")]}>
                  <td class="px-3 py-4 whitespace-nowrap align-top">
                    <button
                      phx-click="toggle_expand"
                      phx-value-booking_id={booking.id}
                      class="flex items-center justify-center size-7 rounded-full text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors"
                    >
                      <.icon
                        name="hero-chevron-down"
                        class={[
                          "w-4 h-4 transition-transform",
                          if(is_expanded, do: "rotate-180", else: "")
                        ]}
                      />
                    </button>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center gap-3">
                      <div class="size-8 rounded-full bg-indigo-50 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
                        <.icon name="hero-building-office" class="w-4 h-4" />
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white">
                          {booking.space.name}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <p class="text-sm text-slate-900 dark:text-slate-200">
                      {SpazioSolazzo.CalendarExt.format_datetime_range_start(booking.start_datetime)}
                    </p>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <p class="text-sm text-slate-900 dark:text-slate-200">
                      {SpazioSolazzo.CalendarExt.format_datetime_range_end(
                        booking.start_datetime,
                        booking.end_datetime
                      )}
                    </p>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div>
                      <p class="font-medium text-slate-900 dark:text-white">
                        {booking.customer_name}
                      </p>
                      <p class="text-xs text-slate-600 dark:text-slate-400">
                        {booking.customer_email}
                      </p>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class={[
                      status_badge_classes(booking.state),
                      "text-xs font-bold px-3 py-1 rounded-full flex items-center gap-1 w-fit"
                    ]}>
                      <.icon name={status_icon(booking.state)} class="w-3.5 h-3.5" />
                      {status_label(booking.state)}
                    </span>
                  </td>
                  <%= if @show_actions do %>
                    <td class="px-6 py-4 whitespace-nowrap text-center">
                      <div class="flex justify-center gap-3">
                        <button
                          phx-click="show_reject_modal"
                          phx-value-booking_id={booking.id}
                          class="flex items-center justify-center px-4 py-2 rounded-lg border border-red-200 dark:border-red-900 text-red-600 dark:text-red-400 bg-white dark:bg-transparent hover:bg-red-50 dark:hover:bg-red-900/20 font-bold text-sm transition-colors"
                        >
                          Reject
                        </button>
                        <button
                          phx-click="approve_booking"
                          phx-value-booking_id={booking.id}
                          class="flex items-center justify-center px-4 py-2 rounded-lg bg-primary hover:bg-primary-hover text-white font-bold text-sm transition-colors shadow-sm"
                        >
                          Confirm
                        </button>
                      </div>
                    </td>
                  <% end %>
                </tr>
                <%= if is_expanded do %>
                  <tr class="bg-slate-50 dark:bg-slate-900/50">
                    <td class="px-3 py-2"></td>
                    <td
                      class="px-6 py-4 text-sm text-slate-600 dark:text-slate-400"
                      colspan={if @show_actions, do: "6", else: "5"}
                    >
                      <div class="flex flex-col gap-2">
                        <p>
                          <strong class="font-semibold text-slate-900 dark:text-white">
                            Phone:
                          </strong>
                          <%= if booking.customer_phone do %>
                            {booking.customer_phone}
                          <% else %>
                            <span class="italic text-slate-400">Not provided</span>
                          <% end %>
                        </p>
                        <p>
                          <strong class="font-semibold text-slate-900 dark:text-white">
                            Note:
                          </strong>
                          <%= if booking.customer_comment do %>
                            {booking.customer_comment}
                          <% else %>
                            <span class="italic text-slate-400">Not provided</span>
                          <% end %>
                        </p>
                        <%= if @show_cancellation_details && booking.state == :rejected do %>
                          <p>
                            <strong class="font-semibold text-slate-900 dark:text-white">
                              Rejection Reason:
                            </strong>
                            <%= if booking.rejection_reason do %>
                              {booking.rejection_reason}
                            <% else %>
                              <span class="italic text-slate-400">Not provided</span>
                            <% end %>
                          </p>
                        <% end %>
                        <%= if @show_cancellation_details && booking.state == :cancelled do %>
                          <p>
                            <strong class="font-semibold text-slate-900 dark:text-white">
                              Cancellation Reason:
                            </strong>
                            <%= if booking.cancellation_reason do %>
                              {booking.cancellation_reason}
                            <% else %>
                              <span class="italic text-slate-400">Not provided</span>
                            <% end %>
                          </p>
                        <% end %>
                      </div>
                    </td>
                  </tr>
                <% end %>
              <% end %>
            </tbody>
          </table>
        </div>
        <.pagination_controls
          page={@page}
          current_page={@current_page}
          event_prefix={@event_prefix}
        />
      </div>
    </div>
    """
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
