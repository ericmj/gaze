defmodule Gaze.SystemChannel do
  use Gaze.Web, :channel

  @update_timer 1000

  # TODO: Do the clever way of finding a more specific OTP version

  @info_system [
    :otp_release,
    :version,
    :system_architecture,
    {:wordsize, :external},
    {:wordsize, :internal},
    :smp_support,
    :threads,
    :thread_pool_size
  ]

  @info_memory [
    :total,
    :processes,
    :atom,
    :binary,
    :code,
    :ets
  ]

  @info_cpu [
    :logical_processors,
    :logical_processors_online,
    :logical_processors_available,
    :schedulers,
    :schedulers_online,
    :schedulers_available
  ]

  @info_stats [
    :uptime,
    :process_limit,
    :process_count,
    :run_queue,
    :io_input,
    :io_output
  ]

  @info_all [
    {@info_system,  :map, &__MODULE__.system_info/1},
    {@info_memory,  :all, &__MODULE__.memory_info/1},
    {@info_cpu,     :map, &__MODULE__.cpu_info/1},
    {@info_stats,   :map, &__MODULE__.stats_info/1}
  ]

  def join("system", _msg, socket) do
    send self, :update
    {:ok, socket}
  end

  def handle_info(:update, socket) do
    :erlang.send_after(@update_timer, self, :update)

    push socket, "update", %{
      panels: panels(@info_all)
    }
    {:noreply, socket}
  end

  defp panels(info) do
    Enum.map(info, fn
      {data, :map, fun} -> Enum.map(data, fun)
      {data, :all, fun} -> fun.(data)
    end)
  end

  def system_info(key) do
    :erlang.system_info(key)
    |> to_string
  end

  def memory_info(keys) do
    :erlang.memory(keys)
    |> Keyword.values
    |> Enum.map(&Util.human_size/1)
  end

  def cpu_info(:schedulers_available) do
    case :erlang.system_info(:multi_scheduling) do
      :enabled -> cpu_info(:schedulers_online)
      _ -> 1
    end
  end
  def cpu_info(key) do
    system_info(key)
  end

  def stats_info(:uptime) do
    :erlang.statistics(:wall_clock)
    |> elem(0)
    |> Util.human_time
  end
  def stats_info(:run_queue) do
    :erlang.statistics(:run_queue)
    |> Integer.to_string
  end
  def stats_info(:io_input) do
    {{:input, input}, _} = :erlang.statistics(:io)
    Util.human_size(input)
  end
  def stats_info(:io_output) do
    {_, {:output, output}} = :erlang.statistics(:io)
    Util.human_size(output)
  end
  def stats_info(key) do
    system_info(key)
    |> Util.human_spaced_number
  end
end
