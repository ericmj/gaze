defmodule Gaze.AllocChannel do
  use Gaze.Web, :channel

  @update_timer 1000

  def join("alloc", _msg, socket) do
    send self, :update
    {:ok, socket}
  end

  def handle_info(:update, socket) do
    :erlang.send_after(@update_timer, self, :update)

    push socket, "update", %{
      alloc: alloc()
    }
    {:noreply, socket}
  end

  defp alloc do
    info = alloc_info()
    Enum.map(info, fn {type, block, carrier} ->
      [type, Util.human_size(block), Util.human_size(carrier)]
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
end
