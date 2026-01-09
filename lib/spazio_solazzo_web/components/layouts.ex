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

  attr :current_user, :map,
    default: nil,
    doc: "the current authenticated user"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <.app_header current_user={@current_user} />

    <main class="bg-slate-50 dark:bg-slate-900 flex-1 relative transition-colors duration-300">
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
    <button
      class="p-2 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400 transition-colors"
      phx-click={
        JS.dispatch("phx:set-theme",
          detail: %{theme: "toggle"}
        )
      }
      title="Toggle Dark Mode"
    >
      <.icon name="hero-sun" class="size-5 [[data-theme=dark]_&]:hidden" />
      <.icon name="hero-moon" class="size-5 hidden [[data-theme=dark]_&]:block" />
    </button>
    """
  end

  defp app_header(assigns) do
    ~H"""
    <header class="sticky top-0 z-50 w-full border-b border-slate-200 dark:border-slate-800 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md px-6 py-4">
      <div class="mx-auto flex h-10 max-w-[1200px] items-center justify-between">
        <.link
          navigate="/"
          class="flex items-center gap-4 text-slate-900 dark:text-slate-100 hover:opacity-80 transition-opacity"
        >
          <div class="flex items-center justify-center size-8 bg-sky-500 rounded-lg text-white shadow-lg shadow-sky-500/20">
            <.icon name="hero-squares-2x2" class="size-5" />
          </div>
          <h2 class="text-lg font-bold leading-tight tracking-tight text-slate-800 dark:text-slate-100">
            Spazio Solazzo
          </h2>
        </.link>

        <div class="flex items-center gap-4">
          <.theme_toggle />
          <%= if @current_user do %>
            <%!-- Desktop menu --%>
            <div class="hidden md:flex items-center gap-3">
              <.link
                navigate={~p"/profile"}
                class="size-10 rounded-full bg-slate-200 dark:bg-slate-700 flex items-center justify-center text-slate-500 dark:text-slate-400 border-2 border-primary/20 hover:border-primary/40 transition-colors"
              >
                <.icon name="hero-user" class="size-5" />
              </.link>
              <.link
                href={~p"/sign-out"}
                id="sign-out-link"
                class="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 hover:text-red-600 hover:bg-red-50 dark:hover:text-red-400 dark:hover:bg-red-950/30 rounded-lg transition-colors border border-slate-300 dark:border-slate-600 hover:border-red-300 dark:hover:border-red-800"
              >
                Sign Out
              </.link>
            </div>
            <%!-- Mobile menu button --%>
            <button
              phx-click={JS.toggle(to: "#mobile-menu")}
              class="md:hidden p-2 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
              id="mobile-menu-button"
            >
              <.icon name="hero-bars-3" class="size-6 text-slate-600 dark:text-slate-400" />
            </button>
          <% else %>
            <.link
              navigate={~p"/sign-in"}
              id="sign-in-link"
              class="px-4 py-2 text-sm font-medium text-white bg-sky-500 hover:bg-sky-600 rounded-lg transition-colors shadow-sm"
            >
              Sign In
            </.link>
          <% end %>
        </div>
      </div>
      <%!-- Mobile dropdown menu --%>
      <%= if @current_user do %>
        <div
          id="mobile-menu"
          class="md:hidden absolute top-full right-0 left-0 mt-2 mx-6 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-lg overflow-hidden"
          style="display: none;"
        >
          <div class="flex flex-col">
            <.link
              navigate={~p"/profile"}
              phx-click={JS.hide(to: "#mobile-menu")}
              class="flex items-center gap-3 px-4 py-3 text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
            >
              <.icon name="hero-user" class="size-5 text-slate-500 dark:text-slate-400" /> Profile
            </.link>
            <.link
              href={~p"/sign-out"}
              id="mobile-sign-out-link"
              class="flex items-center gap-3 px-4 py-3 text-sm font-medium text-red-600 dark:text-red-500 hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors border-t border-slate-200 dark:border-slate-800"
            >
              <.icon name="hero-arrow-right-on-rectangle" class="size-5" /> Sign Out
            </.link>
          </div>
        </div>
      <% end %>
    </header>
    """
  end

  defp footer(assigns) do
    current_year = Date.utc_today().year

    assigns = assign(assigns, :current_year, current_year)

    ~H"""
    <footer class="border-t border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 py-12 px-6 transition-colors duration-300">
      <div class="mx-auto max-w-[1200px] flex flex-col md:flex-row justify-between gap-8">
        <div class="flex flex-col gap-4 max-w-sm">
          <div class="flex items-center gap-3 text-slate-900 dark:text-slate-100">
            <div class="flex items-center justify-center size-6 bg-sky-500 rounded text-white">
              <.icon name="hero-squares-2x2" class="size-4" />
            </div>
            <h2 class="text-base font-bold">Spazio Solazzo</h2>
          </div>
          <p class="text-sm text-slate-500 dark:text-slate-400">
            A community-driven space dedicated to work, creativity, and connection.
          </p>
        </div>

        <div class="flex gap-16 flex-wrap">
          <div>
            <h3 class="text-sm font-bold text-slate-900 dark:text-slate-100 uppercase tracking-wider mb-4">
              Spaces
            </h3>
            <ul class="flex flex-col gap-3">
              <li>
                <a
                  href="/coworking"
                  class="text-sm text-slate-500 dark:text-slate-400 hover:text-sky-500 transition-colors"
                >
                  Coworking
                </a>
              </li>
              <li>
                <a
                  href="/meeting"
                  class="text-sm text-slate-500 dark:text-slate-400 hover:text-sky-500 transition-colors"
                >
                  Meeting Room
                </a>
              </li>
              <li>
                <a
                  href="/music"
                  class="text-sm text-slate-500 dark:text-slate-400 hover:text-sky-500 transition-colors"
                >
                  Music Room
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h3 class="text-sm font-bold text-slate-900 dark:text-slate-100 uppercase tracking-wider mb-4">
              Community
            </h3>
            <ul class="flex flex-col gap-3">
              <li>
                <a
                  href="https://caravanseraipalermo.it/"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-sm text-slate-500 dark:text-slate-400 hover:text-sky-500 transition-colors"
                >
                  Caravanserai Palermo
                </a>
              </li>
              <li>
                <a
                  href="https://mojocohouse.com/"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-sm text-slate-500 dark:text-slate-400 hover:text-sky-500 transition-colors"
                >
                  Mojo Cohouse
                </a>
              </li>
              <li>
                <a
                  href="https://jaster.xyz"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-sm text-slate-500 dark:text-slate-400 hover:text-sky-500 transition-colors"
                >
                  Author's Blog
                </a>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <div class="mx-auto max-w-[1200px] mt-12 pt-8 border-t border-slate-100 dark:border-slate-800 text-center md:text-left">
        <p class="text-xs text-slate-500">
          © {@current_year} Spazio Solazzo. All rights reserved.
        </p>
      </div>
    </footer>
    """
  end
end
