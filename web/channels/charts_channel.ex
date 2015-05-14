defmodule Gaze.ChartsChannel do
  use Phoenix.Channel

  @update_timer 1000

  @info_memory [
    :total,
    :processes,
    :atom,
    :binary,
    :code,
    :ets
  ]

  def join("charts", _msg, socket) do
    send self, :update
    :erlang.system_flag(:scheduler_wall_time, true)
    {:ok, socket}
  end

  def handle_info(:update, socket) do
    :erlang.send_after(@update_timer, self, :update)

    {wall_diff, socket} = wall_time(socket)
    {io_diff, socket} = io(socket)

    push socket, "update", %{
      schedulers: wall_diff,
      memory: memory(),
      io: io_diff
    }
    {:noreply, socket}
  end

  defp wall_time(socket) do
    new_wall_time =
      :erlang.statistics(:scheduler_wall_time)
      |> Enum.sort

    if old_wall_time = socket.assigns[:wall_time] do
      wall_diff =
        Enum.zip(old_wall_time, new_wall_time)
        |> Enum.map(fn {{_, a0, t0}, {_, a1, t1}} -> (a1-a0) / (t1-t0) end)
    else
      wall_diff = Enum.map(new_wall_time, fn _ -> 0.0 end)
    end

    socket = assign(socket, :wall_time, new_wall_time)
    {wall_diff, socket}
  end

  defp memory do
    :erlang.memory(@info_memory)
    |> Keyword.values
    |> Enum.map(&div(&1, 1024 * 1024))
  end

  defp io(socket) do
    {{:input, input}, {:output, output}} = :erlang.statistics(:io)
    new_io = [input, output]

    if old_io = socket.assigns[:io] do
      io_diff =
        Enum.zip(old_io, new_io)
        |> Enum.map(fn {old, new} -> div(new-old, 1024) end)
    else
      io_diff = [0, 0]
    end

    socket = assign(socket, :io, new_io)
    {io_diff, socket}
  end
end
