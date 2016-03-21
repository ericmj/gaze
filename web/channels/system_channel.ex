defmodule Gaze.SystemChannel do
  use Phoenix.Channel

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
      panels: panels(@info_all),
      alloc: alloc()
    }
    {:noreply, socket}
  end

  defp panels(info) do
    Enum.map(info, fn
      {data, :map, fun} -> Enum.map(data, fun)
      {data, :all, fun} -> fun.(data)
    end)
  end

  defp alloc do
    info = alloc_info()
    Enum.map(info, fn {type, block, carrier} ->
      [type, human_size(block), human_size(carrier)]
    end)
  end

  defp alloc_info do
    alcu_allocs = :erlang.system_info(:alloc_util_allocators)
    :erlang.system_info({:allocator_sizes, alcu_allocs})
    |> alloc_info([], 0, 0, true)
  end

  defp alloc_info([{type,instances} | allocators], type_acc, total_bs, total_cs, include_total) do
    {bs, cs, total_bs, total_cs, new_include_total} =
      sum_alloc_instances(instances, 0, 0, total_bs, total_cs)
    alloc_info(allocators, [{type,bs,cs}|type_acc], total_bs, total_cs, include_total and new_include_total)
  end
  defp alloc_info([], type_acc, total_bs, total_cs, include_total) do
    types = for x={_,bs,cs} <- type_acc, (bs>0 or cs>0), do: x
    if include_total do
      [{:total,total_bs,total_cs} | Enum.reverse(types)]
    else
      Enum.reverse(types)
    end
  end

  defp sum_alloc_instances(false, bs, cs, total_bs, total_cs) do
    {bs, cs, total_bs, total_cs, false}
  end
  defp sum_alloc_instances([{_,_,data} | instances], bs, cs, total_bs, total_cs) do
    {bs, cs, total_bs, total_cs} =
      sum_alloc_one_instance(data, bs, cs, total_bs, total_cs)
    sum_alloc_instances(instances, bs, cs, total_bs, total_cs)
  end
  defp sum_alloc_instances([], bs, cs, total_bs, total_cs) do
    {bs, cs, total_bs, total_cs, true}
  end

  defp sum_alloc_one_instance([{:sbmbcs,[{:blocks_size,bs,_,_},{:carriers_size,cs,_,_}]} | rest], old_bs, old_cs, total_bs, total_cs) do
    sum_alloc_one_instance(rest, old_bs+bs, old_cs+cs, total_bs, total_cs)
  end
  defp sum_alloc_one_instance([{_,[{:blocks_size,bs,_,_},{:carriers_size,cs,_,_}]} | rest], old_bs, old_cs, total_bs, total_cs) do
    sum_alloc_one_instance(rest, old_bs+bs, old_cs+cs, total_bs+bs, total_cs+cs)
  end
  defp sum_alloc_one_instance([{_,[{:blocks_size,bs},{:carriers_size,cs}]} | rest], old_bs, old_cs, total_bs, total_cs) do
    sum_alloc_one_instance(rest, old_bs+bs, old_cs+cs, total_bs+bs, total_cs+cs)
  end
  defp sum_alloc_one_instance([_|rest], bs, cs, total_bs, total_cs) do
    sum_alloc_one_instance(rest, bs, cs, total_bs, total_cs)
  end
  defp sum_alloc_one_instance([], bs, cs, total_bs, total_cs) do
    {bs, cs, total_bs, total_cs}
  end

  def system_info(key) do
    :erlang.system_info(key)
    |> to_string
  end

  def memory_info(keys) do
    :erlang.memory(keys)
    |> Keyword.values
    |> Enum.map(&human_size/1)
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
    |> Integer.to_string
  end
  def stats_info(:io_input) do
    {{:input, input}, _} = :erlang.statistics(:io)
    human_size(input)
  end
  def stats_info(:io_output) do
    {_, {:output, output}} = :erlang.statistics(:io)
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
