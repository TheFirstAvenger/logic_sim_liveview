defmodule LogicSimLiveviewWeb.PageController do
  use LogicSimLiveviewWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
