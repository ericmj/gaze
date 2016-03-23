defmodule Gaze.Util do
  @kb_size 1024
  @mb_size 1024 * @kb_size
  @gb_size 1024 * @mb_size

  def human_size(size) when size < @kb_size * 10,
    do: "#{human_spaced_number(size)} B"
  def human_size(size) when size < @mb_size * 10,
    do: "#{human_spaced_number(div(size, @kb_size))} kB"
  def human_size(size),
    do: "#{human_spaced_number(div(size, @mb_size))} MB"

  @sec_time  1000
  @min_time  60 * @sec_time
  @hour_time 60 * @min_time
  @day_time  24 * @hour_time

  def human_time(ms) when ms < @min_time,
    do: "#{human_spaced_number(div(ms, @sec_time))} secs"
  def human_time(ms) when ms < @hour_time,
    do: "#{human_spaced_number(div(ms, @min_time))} mins"
  def human_time(ms) when ms < @day_time,
    do: "#{human_spaced_number(div(ms, @hour_time))} hours"
  def human_time(ms),
    do: "#{human_spaced_number(div(ms, @day_time))} days"

  def human_spaced_number(string) when is_binary(string) do
    split         = rem(byte_size(string), 3)
    string        = :erlang.binary_to_list(string)
    {first, rest} = Enum.split(string, split)
    rest          = Enum.chunk(rest, 3) |> Enum.map(&[" ", &1])
    IO.iodata_to_binary([first, rest])
  end

  def human_spaced_number(int) when is_integer(int) do
    human_spaced_number(Integer.to_string(int))
  end
end
