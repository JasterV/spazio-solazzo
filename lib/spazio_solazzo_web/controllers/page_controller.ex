defmodule SpazioSolazzoWeb.PageController do
  use SpazioSolazzoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
