defmodule Gaze.GazeController do
  use Gaze.Web, :controller

  plug :action

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end
