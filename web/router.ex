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

  scope "/", Gaze do
    pipe_through :browser # Use the default browser stack

    get "/gaze", GazeController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", Gaze do
  #   pipe_through :api
  # end
end
