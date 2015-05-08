defmodule Gaze.GazeControllerTest do
  use Gaze.ConnCase

  setup do
    conn = conn()
    {:ok, conn: conn}
  end

  test "GET /gazes", %{conn: conn} do
    conn = get conn, gaze_path(conn, :index)
    assert html_response(conn, 200) =~ "Loading Gaze"
  end
end
