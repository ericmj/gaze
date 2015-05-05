defmodule Gaze.PageController do
  use Gaze.Web, :controller

  plug :action

  def index(conn, _params) do
    render conn, "index.html"
  end
end
