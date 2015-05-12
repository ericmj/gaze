defmodule Gaze.SystemChannel do
  use Phoenix.Channel

  @update_timer 1000

  @info_system [
    {"System version",          :otp_release},
    {"ERTS version",            :version},
    {"Compiled for",            :system_architecture},
    {"Emulator wordsize",       {:wordsize, :external}},
    {"Process wordsize",        {:wordsize, :internal}},
    {"SMP support",             :smp_support},
    {"Thread support",          :threads},
    {"Async thread pool size",  :thread_pool_size}
  ]

  @info_memory [
    {"Total",     :total},
    {"Processes", :processes},
    {"Atoms",     :atom},
    {"Binaries",  :binary},
    {"Code",      :code},
    {"ETS",       :ets}
  ]

  @info_cpu [
    {"Logical CPUs",           :logical_processors},
    {"Online logical CPUs",    :logical_processors_online},
    {"Available logical CPUs", :logical_processors_available},
    {"Schedulers",              :schedulers},
    {"Online schedulers",       :schedulers_online},
    {"Available schedulers",    :schedulers_available}
  ]

  @info_stats [
    {"Up time",       :uptime},
    {"Max processes", :process_limit},
    {"Processes",     :process_count},
    {"Run queue",     :run_queue},
    {"IO input",      :io_input},
    {"IO output",     :io_output}
  ]

  @info_all [
    {"System and architecture", &__MODULE__.system_info/1, @info_system},
    {"Memory usage", &__MODULE__.memory_info/1, @info_memory},
    {"CPUs and threads", &__MODULE__.cpu_info/1, @info_cpu},
    {"Statistics", &__MODULE__.stats_info/1, @info_stats}
  ]

  def join("system", _msg, socket) do
    send self, :update
    {:ok, socket}
  end

  def handle_info(:update, socket) do
    :erlang.send_after(@update_timer, self, :update)
    push socket, "update", %{info: info(@info_all)}
    {:noreply, socket}
  end

  defp info(info) do
    Enum.map(info, fn {name, fun, data} ->
      %{name: name, data: collect(data, fun)}
    end)
    |> Enum.chunk(2, 2, [])
  end

  defp collect(info, fun) do
    Enum.map(info, fn {name, key} ->
      %{name: name, value: fun.(key)}
    end)
  end

  def system_info(key) do
    :erlang.system_info(key)
    |> to_string
  end

  def memory_info(key) do
    :erlang.memory(key)
    |> human_size
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
    |> human_time
  end
  def stats_info(:run_queue) do
    :erlang.statistics(:run_queue)
  end
  def stats_info(:io_input) do
    {{_, input}, _} = :erlang.statistics(:io)
    human_size(input)
  end
  def stats_info(:io_output) do
    {_, {_, output}} = :erlang.statistics(:io)
    human_size(output)
  end
  def stats_info(key) do
    system_info(key)
    |> human_spaced_number
  end

  @kb_size 1024
  @mb_size 1024 * @kb_size
  @gb_size 1024 * @mb_size

  defp human_size(size) when size < @kb_size * 10,
    do: "#{human_spaced_number(size)} B"
  defp human_size(size) when size < @mb_size * 10,
    do: "#{human_spaced_number(div(size, @kb_size))} kB"
  defp human_size(size),
    do: "#{human_spaced_number(div(size, @mb_size))} MB"

  @sec_time  1000
  @min_time  60 * @sec_time
  @hour_time 60 * @min_time
  @day_time  24 * @hour_time

  defp human_time(ms) when ms < @min_time,
    do: "#{human_spaced_number(div(ms, @sec_time))} secs"
  defp human_time(ms) when ms < @hour_time,
    do: "#{human_spaced_number(div(ms, @min_time))} mins"
  defp human_time(ms) when ms < @day_time,
    do: "#{human_spaced_number(div(ms, @hour_time))} hours"
  defp human_time(ms),
    do: "#{human_spaced_number(div(ms, @day_time))} days"

  defp human_spaced_number(string) when is_binary(string) do
    split         = rem(byte_size(string), 3)
    string        = :erlang.binary_to_list(string)
    {first, rest} = Enum.split(string, split)
    rest          = Enum.chunk(rest, 3) |> Enum.map(&[" ", &1])
    IO.iodata_to_binary([first, rest])
  end

  defp human_spaced_number(int) when is_integer(int) do
    human_spaced_number(Integer.to_string(int))
  end
end
