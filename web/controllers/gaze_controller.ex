defmodule Gaze.GazeController do
  use Gaze.Web, :controller

  plug :action

  @info_system [
    {"System Version",          :otp_release},
    {"ERTS Version",            :version},
    {"Compiled for",            :system_architecture},
    {"Emulator Wordsize",       {:wordsize, :external}},
    {"Process Wordsize",        {:wordsize, :internal}},
    {"Smp Support",             :smp_support},
    {"Thread Support",          :threads},
    {"Async thread pool size",  :thread_pool_size}
  ]

  @info_all [
    {"System and Architecture", @info_system},
    {"Memory Usage", []}
  ]

  def index(conn, _params) do
    conn
    |> assign(:info, info(@info_all))
    |> render("index.html")
  end

  defp info(info) do
    Enum.map(info, fn {name, data} ->
      %{name: name, data: collect(data)}
    end)
    |> Enum.chunk(2)
    |> Poison.encode!
  end

  defp collect(info) do
    Enum.map(info, fn {name, key} ->
      %{name: name, value: system_info(key)}
    end)
  end

  defp system_info(key) do
    :erlang.system_info(key)
    |> to_string
  end
end
