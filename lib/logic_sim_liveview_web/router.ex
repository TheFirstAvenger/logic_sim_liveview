defmodule LogicSimLiveviewWeb.Router do
  use LogicSimLiveviewWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LogicSimLiveviewWeb do
    pipe_through :browser

    get "/", PageController, :index
    live("/logic_sim", LogicSimLive)
  end

  # Other scopes may use custom stacks.
  # scope "/api", LogicSimLiveviewWeb do
  #   pipe_through :api
  # end
end
