defmodule SpazioSolazzoWeb.EmailView do
  use SpazioSolazzoWeb, :html

  embed_templates "email_templates/*"

  @doc """
  Renders the main container for the email.
  """
  slot :inner_block, required: true

  def email_container(assigns) do
    ~H"""
    <div class="container">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a primary or secondary action button.
  accepts: :primary (orange) or :danger (red)
  """
  attr :href, :string, required: true
  attr :variant, :atom, default: :primary, values: [:primary, :danger]
  slot :inner_block, required: true

  def email_button(assigns) do
    ~H"""
    <div class="btn-wrapper">
      <.link href={@href} class={["btn", "btn-#{@variant}"]} target="_blank">
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a styled list for booking details.
  """
  slot :inner_block, required: true

  def details_list(assigns) do
    ~H"""
    <ul class="details-list">
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc """
  Renders a single detail item.
  """
  attr :label, :string, required: true
  slot :inner_block, required: true

  def detail_item(assigns) do
    ~H"""
    <li><strong>{@label}:</strong> {render_slot(@inner_block)}</li>
    """
  end

  def render(template, assigns) when is_binary(template) do
    template
    |> Path.rootname()
    |> String.to_atom()
    |> then(fn name ->
      if function_exported?(__MODULE__, name, 1) do
        apply(__MODULE__, name, [assigns])
      else
        raise "template #{template} not implemented in #{__MODULE__}"
      end
    end)
  end
end
