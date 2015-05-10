defmodule Gaze.SystemChannel do
  use Phoenix.Channel

  @update_timer 1000

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

  @info_memory [
    {"Total",     :total},
    {"Processes", :processes},
    {"Atoms",     :atom},
    {"Binaries",  :binary},
    {"Code",      :code},
    {"ETS",       :ets}
  ]

  @info_all [
    {"System and Architecture", &__MODULE__.system_info/1, @info_system},
    {"Memory Usage", &__MODULE__.memory/1, @info_memory}
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
    |> Enum.chunk(2)
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

  def memory(key) do
    :erlang.memory(key)
    |> human_size
  end

  @kb_size 1024
  @mb_size 1024 * @kb_size
  @gb_size 1024 * @mb_size

  defp human_size(size) when size < @kb_size * 10,
    do: "#{human_number_space(size)} B"
  defp human_size(size) when size < @mb_size * 10,
    do: "#{human_number_space(div(size, @kb_size))} kB"
  defp human_size(size),
    do: "#{human_number_space(div(size, @mb_size))} MB"

  def human_number_space(string) when is_binary(string) do
    split         = rem(byte_size(string), 3)
    string        = :erlang.binary_to_list(string)
    {first, rest} = Enum.split(string, split)
    rest          = Enum.chunk(rest, 3) |> Enum.map(&[" ", &1])
    IO.iodata_to_binary([first, rest])
  end

  def human_number_space(int) when is_integer(int) do
    human_number_space(Integer.to_string(int))
  end
end
