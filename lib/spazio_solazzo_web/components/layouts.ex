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

    <main class="bg-base-100 flex-1 relative transition-colors duration-300">
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
      class="p-2 rounded-full hover:bg-base-200 text-neutral transition-colors"
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

  attr :current_user, :map,
    default: nil,
    doc: "the current authenticated user"

  defp app_header(assigns) do
    ~H"""
    <header class="sticky top-0 z-50 w-full border-b border-base-200 bg-base-100 backdrop-blur-md px-6 py-4">
      <div class="mx-auto flex h-10 max-w-[1200px] items-center justify-between">
        <.link navigate="/" class="flex items-center gap-3 hover:opacity-80 transition-opacity">
          <img src="/images/logo.png" alt="Spazio Solazzo" class="h-8" />
        </.link>

        <div class="flex items-center gap-4">
          <.theme_toggle />
          <%= if @current_user do %>
            <%!-- Desktop menu --%>
            <div class="hidden md:flex items-center gap-3">
              <.link
                navigate={~p"/profile"}
                class="btn btn-circle btn-outline text-primary hover:bg-info/10"
              >
                <.icon name="hero-user" class="size-6" />
              </.link>
              <.link
                href={~p"/sign-out"}
                id="sign-out-link"
                class="btn btn-outline btn-error btn-sm hover:text-error hover:bg-error/10"
              >
                Sign Out
              </.link>
            </div>
            <%!-- Mobile menu button --%>
            <button
              phx-click={JS.toggle(to: "#mobile-menu")}
              class="btn btn-ghost btn-sm md:hidden text-neutral"
              id="mobile-menu-button"
            >
              <.icon name="hero-bars-3" class="size-6" />
            </button>
          <% else %>
            <.link navigate={~p"/sign-in"} id="sign-in-link" class="btn btn-secondary btn-sm">
              Sign In
            </.link>
          <% end %>
        </div>
      </div>
      <%!-- Mobile dropdown menu --%>
      <%= if @current_user do %>
        <div
          id="mobile-menu"
          class="md:hidden absolute top-full right-0 left-0 mt-2 mx-6 bg-base-100 border border-base-200 rounded-xl shadow-lg overflow-hidden"
          style="display: none;"
        >
          <div class="menu">
            <.link
              navigate={~p"/profile"}
              phx-click={JS.hide(to: "#mobile-menu")}
              class="flex items-center gap-3 px-4 py-3 text-sm font-medium hover:bg-accent/10 text-neutral transition-colors"
            >
              <.icon name="hero-user" class="size-5 text-primary" /> Profile
            </.link>
            <.link
              href={~p"/sign-out"}
              id="mobile-sign-out-link"
              class="flex items-center gap-3 px-4 py-3 text-sm font-medium hover:bg-error/10 text-error transition-colors border-t border-base-200"
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
              Spaces
            </h3>
            <ul class="flex flex-col gap-3">
              <li>
                <a
                  href="/coworking"
                  class="text-sm text-neutral hover:text-secondary transition-colors"
                >
                  Coworking
                </a>
              </li>
              <li>
                <a
                  href="/meeting"
                  class="text-sm text-neutral hover:text-secondary transition-colors"
                >
                  Meeting Room
                </a>
              </li>
              <li>
                <a
                  href="/music"
                  class="text-sm text-neutral hover:text-secondary transition-colors"
                >
                  Music Room
                </a>
              </li>
            </ul>
          </div>

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
end
