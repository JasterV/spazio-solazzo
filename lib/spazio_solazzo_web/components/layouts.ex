defmodule SpazioSolazzoWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use SpazioSolazzoWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8 bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800">
      <div class="flex-1">
        <a href="/" class="flex-1 flex w-fit items-center gap-2">
          <span class="text-xl font-bold text-gray-900 dark:text-white">Spazio Solazzo</span>
        </a>
      </div>
      <div class="flex-none">
        <.theme_toggle />
      </div>
    </header>

    <main class="bg-gradient-to-br from-indigo-50 via-white to-purple-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900 flex-1 relative">
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />

    <.footer />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/2 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 [[data-theme=light]_&]:left-0 [[data-theme=dark]_&]:left-1/2 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/2"
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/2"
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  defp footer(assigns) do
    current_year = Date.utc_today().year

    assigns = assign(assigns, :current_year, current_year)

    ~H"""
    <footer class="bg-gray-100 dark:bg-gray-800 mt-auto">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div class="space-y-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Community</h3>
            <ul class="space-y-2">
              <li>
                <a
                  href="https://caravanseraipalermo.it/"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-teal-600 dark:text-teal-400 hover:text-teal-700 dark:hover:text-teal-300 transition-colors"
                >
                  Caravanserai Palermo
                </a>
              </li>
              <li>
                <a
                  href="https://mojocohouse.com/"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-teal-600 dark:text-teal-400 hover:text-teal-700 dark:hover:text-teal-300 transition-colors"
                >
                  Mojo Cohouse
                </a>
              </li>
              <li>
                <a
                  href="https://jaster.xyz"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-teal-600 dark:text-teal-400 hover:text-teal-700 dark:hover:text-teal-300 transition-colors"
                >
                  Author's Blog
                </a>
              </li>
            </ul>
          </div>

          <div class="space-y-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">About</h3>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              © {@current_year} Victor Martinez & Spazio Solazzo. All rights reserved.
            </p>
          </div>
        </div>
      </div>
    </footer>
    """
  end
end
