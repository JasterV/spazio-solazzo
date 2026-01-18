defmodule SpazioSolazzoWeb.AdminComponents do
  @moduledoc """
  Reusable components for admin pages (dashboard & tools).
  """
  use Phoenix.Component

  import SpazioSolazzoWeb.CoreComponents, only: [icon: 1, button: 1]
  import Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: SpazioSolazzoWeb.Endpoint,
    router: SpazioSolazzoWeb.Router,
    statics: SpazioSolazzoWeb.static_paths()

  @doc """
  Cards displayed for each tool available to admins
  """
  attr :id, :string, doc: "optional id for the tool"
  attr :title, :string
  attr :icon, :string, doc: "Icon used to represent the type of tool"
  attr :description, :string

  def tool_card(assigns) do
    ~H"""
    <div class="card bg-base-100 text-base-content shadow-xl border border-base-200 hover:shadow-2xl transition-shadow cursor-pointer">
      <div class="card-body">
        <h2 class="card-title flex items-center gap-2">
          <.icon name={@icon} class="size-6 text-secondary" /> {@title}
        </h2>
        <p class="text-base-content/70 mt-2">{@description}</p>
        <div class="card-actions justify-end mt-4">
          <.button class="btn btn-primary btn-sm">Open</.button>
        </div>
      </div>
    </div>
    """
  end
end
