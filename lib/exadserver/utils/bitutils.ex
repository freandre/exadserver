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
  Generate a tuple {data, size} of values of size size with 0
  """
  def generateAllWithZero(size) when size >= 0 do
    generateAll(size, false)
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
  def conditionalNot({data, size} = value, change) do
    if (change) do
      negate({data, size})
    else
      value
    end
  end

  @doc """
    Logical negation of a bit structure
  """
  def negate({key, size}) do
    {ones, _} = generateAllWithOne(size)
    {ones ^^^ key, size}
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
  def setBitAt({value, size}, bit, position) when position < size do
    if bit == 1 do
      {value ||| (1 <<< position), size}
    else
      # 1's complement for bitwise not
      {value &&& elem(negate({1 <<< position, position + 1}), 0), size}      
    end
  end

  @doc """
    Print a bit structure in binary form
  """
  def dumpBits(key) when is_integer(key) do
    IO.puts("Key: " <> inspect(Integer.digits(key, 2)))
  end

  @doc """
    Print a bit structure in binary form
  """
  def dumpBits({key, size}) do
    IO.puts("Key(" <> Integer.to_string(size) <> "): "
                   <> inspect(Integer.digits(key, 2)))
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
