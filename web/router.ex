defmodule Gaze.Router do
  use Gaze.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/gaze", Gaze do
    pipe_through :browser # Use the default browser stack

    get "/", GazeController, :index
  end

  socket "/gaze/ws", Gaze, via: [Phoenix.Transports.WebSocket] do
    channel "system", SystemChannel
  end

  # Other scopes may use custom stacks.
  # scope "/api", Gaze do
  #   pipe_through :api
  # end
end
