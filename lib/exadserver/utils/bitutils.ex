defmodule ExAdServer.Utils.BitUtils do
  @moduledoc """
  Bit manipulation utility module.
  """

  use Bitwise

  @doc """
  Generate a tuple {data, size} of values of size size with 1
  """
  def generateAllWithOne(size) when size >= 0 do
    generateAll(size, true)
  end

  @doc """
  Add a 1 bit
  """
  def addOne({data, size}) do
    {(data <<< 1) ||| 1, size + 1}
  end

  @doc """
  Add a 0 bit
  """
  def addZero({data, size}) do
    {(data <<< 1), size + 1}
  end


  @doc """
  Negate the data of the tuple is no_change is false
  """
  def excludeIfNeeded({data, size} = value, no_change) do
    case no_change do
      false -> {~~~data, size}
      _ -> value
    end
  end

  @doc """
  Generate a tuple {data, size} of values of size size with 0
  """
  def generateAllWithZero(size) when size >= 0 do
    generateAll(size, false)
  end

  @doc """
    Aggregator for tuple {data, size}
  """
  def aggregateAccumulators({firstData, firstSize}, {secData, secSize}) do
    {(firstData <<< secSize) ||| secData, firstSize + secSize}
  end

  @doc """
    Put a specific bit at position
  """
  def setBitAt({value, size}, bit, position) do
    #IO.puts(inspect(Integer.digits(value, 2)))
    if bit == 1 do
      #IO.puts(inspect(Integer.digits(value ||| (bit <<< position), 2)))
      {value ||| (bit <<< position), size}
    else
      #IO.puts(inspect(Integer.digits(value &&& ~~~(1 <<< position), 2)))
      {value &&& ~~~(1 <<< position), size}
    end
  end

  ## Private functions

  ## Generate a tuple {data, size} of values of size size with 1 if fillWithOne
  ## is true, 0 else
  defp generateAll(size, fillWithOne) when size >= 0 do
    if fillWithOne do
      {generateOne(0, size), size}
    else
      {0, size}
    end
  end

  ## Generate a tuple {data, size} of 1's of size size by shifting data
  defp generateOne(data, size) do
    case size do
      0 -> data
      _ -> generateOne((data <<< 1) ||| 1, size - 1)
    end
  end
end
