defmodule LogicSimLiveviewWeb.PageController do
  use LogicSimLiveviewWeb, :controller

  def index(conn, _params) do
    conn |> redirect(to: "/logic_sim") |> halt()
  end
end
