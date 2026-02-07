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
    current_year = Date.utc_today().year

    assigns = assign(assigns, :current_year, current_year)

    ~H"""
    <header class="sticky top-0 z-50 navbar bg-base-100 shadow-sm dark:shadow-white/40 pr-4 pl-4 text-base-content">
      <div class="navbar-start">
        <.link navigate="/" class="flex items-center gap-3 hover:opacity-80 transition-opacity">
          <img src="/images/logo.png" alt="Spazio Solazzo" class="h-8" />
        </.link>
      </div>
      <div class="navbar-center hidden md:flex">
        <ul class="menu menu-horizontal px-1">
          <%= if @current_user && @current_user.is_admin do %>
            <li>
              <.link class="dark:hover:bg-secondary/20" navigate={~p"/admin/dashboard"}>
                Dashboard
              </.link>
            </li>
          <% end %>
        </ul>
      </div>
      <div class="navbar-end flex gap-3">
        <.theme_toggle />

        <%= if @current_user do %>
          <%!-- Desktop Menu --%>
          <div class="hidden md:flex items-center gap-3">
            <.link
              navigate={~p"/profile"}
              class="btn btn-circle btn-outline text-secondary hover:bg-info/10"
              aria-label="Profile"
            >
              <.icon name="hero-user" class="size-6" />
            </.link>
          </div>
        <% else %>
          <.link navigate={~p"/sign-in"} id="sign-in-link" class="btn btn-secondary btn-sm">
            Sign In
          </.link>
        <% end %>

        <%!-- Mobile menu --%>
        <%= if @current_user do %>
          <div class="dropdown dropdown-end">
            <div
              tabindex="0"
              role="button"
              class="btn btn-ghost p-2 hover:bg-secondary/20 border-none"
            >
              <.menu_svg />
            </div>
            <ul
              tabindex="-1"
              class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow dark:shadow-none dark:border dark:border-white/40 bg-base-100 rounded-box w-52"
            >
              <%= if @current_user && @current_user.is_admin do %>
                <li class="md:hidden">
                  <.link navigate={~p"/admin/dashboard"}>
                    <.icon name="hero-squares-2x2" class="size-4" /> Dashboard
                  </.link>
                </li>
              <% end %>

              <li class="md:hidden">
                <.link navigate={~p"/profile"}>
                  <.icon name="hero-user" class="size-4" /> Profile
                </.link>
              </li>
              <li>
                <.link href={~p"/sign-out"} id="mobile-sign-out-link" class="text-error">
                  <.icon name="hero-arrow-right-on-rectangle" class="size-4" /> Sign Out
                </.link>
              </li>
            </ul>
          </div>
        <% end %>
      </div>
    </header>

    <main class="bg-base-100 flex-1 relative transition-colors duration-300">
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />

    <footer class="footer border-t border-base-200 bg-base-100 py-12 px-6">
      <div class="mx-auto max-w-[1200px] w-full flex flex-col md:flex-row justify-between gap-8">
        <div class="flex flex-col gap-4 max-w-sm">
          <div class="flex items-center gap-3">
            <img src="/images/logo.png" alt="Spazio Solazzo" class="h-6" />
          </div>
          <p class="text-sm text-neutral">
            A community-driven space dedicated to work, creativity, and connection.
          </p>
          <p class="text-xs text-neutral">
            © {@current_year} Spazio Solazzo. All rights reserved.
          </p>
        </div>

        <div class="flex gap-16 flex-wrap md:justify-end">
          <div>
            <h3 class="text-sm font-bold text-base-content uppercase tracking-wider mb-4">
              Community
            </h3>
            <ul class="flex flex-col gap-3">
              <li>
                <a
                  href="https://caravanseraipalermo.it/"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-sm text-neutral hover:text-secondary transition-colors"
                >
                  Caravanserai Palermo
                </a>
              </li>
              <li>
                <a
                  href="https://mojocohouse.com/"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-sm text-neutral hover:text-secondary transition-colors"
                >
                  Mojo Cohouse
                </a>
              </li>
              <li>
                <a
                  href="https://jaster.xyz"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-sm text-neutral hover:text-secondary transition-colors"
                >
                  Author's Blog
                </a>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </footer>
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
      class="p-2 rounded-full hover:bg-base-200 text-neutral transition-colors cursor-pointer"
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

  defp menu_svg(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="h-5 w-5"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M4 6h16M4 12h8m-8 6h16"
      />
    </svg>
    """
  end
end
