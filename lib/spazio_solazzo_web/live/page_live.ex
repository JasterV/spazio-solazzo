defmodule SpazioSolazzoWeb.PageLive do
  use SpazioSolazzoWeb, :live_view

  def mount(_params, _session, socket) do
    spaces = [
      %{
        name: "Coworking",
        slug: "coworking",
        description: "Flexible desk spaces for remote work"
      },
      %{
        name: "Meeting Room",
        slug: "meeting",
        description: "Private conference rooms by the hour"
      },
      %{name: "Music Studio", slug: "music", description: "Evening recording sessions"}
    ]

    {:ok, assign(socket, spaces: spaces)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div class="text-center mb-16">
          <h1 class="text-5xl font-bold text-gray-900 dark:text-white mb-4">Spazio Solazzo</h1>
          <p class="text-xl text-gray-600 dark:text-gray-300">Book your perfect workspace</p>
        </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <%= for space <- @spaces do %>
              <.link
                navigate={"/#{space.slug}"}
                class={[
                  "group relative overflow-hidden rounded-2xl bg-white dark:bg-gray-800 p-8",
                  "shadow-lg hover:shadow-2xl dark:shadow-gray-900/50 transition-all duration-300",
                  "transform hover:-translate-y-2 border border-transparent dark:border-gray-700"
                ]}
              >
                <div class="relative z-10">
                  <div class="mb-6">
                    <div class="w-16 h-16 rounded-full bg-indigo-100 dark:bg-indigo-900 flex items-center justify-center group-hover:bg-indigo-200 dark:group-hover:bg-indigo-800 transition-colors">
                      <svg
                        class="w-8 h-8 text-indigo-600 dark:text-indigo-400"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                        />
                      </svg>
                    </div>
                  </div>
                  <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-3">{space.name}</h2>
                  <p class="text-gray-600 dark:text-gray-300 mb-6">{space.description}</p>
                  <div class="flex items-center text-indigo-600 dark:text-indigo-400 font-semibold group-hover:text-indigo-700 dark:group-hover:text-indigo-300">
                    <span>Book now</span>
                    <svg
                      class="w-5 h-5 ml-2 transform group-hover:translate-x-1 transition-transform"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M13 7l5 5m0 0l-5 5m5-5H6"
                      />
                    </svg>
                  </div>
                </div>
                <div class="absolute inset-0 bg-gradient-to-br from-indigo-500/0 to-purple-500/0 group-hover:from-indigo-500/5 group-hover:to-purple-500/5 dark:group-hover:from-indigo-400/10 dark:group-hover:to-purple-400/10 transition-all duration-300">
                </div>
              </.link>
            <% end %>
          </div>
        </div>
    </Layouts.app>
    """
  end
end
