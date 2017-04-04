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
  def setBitAt({value, size}, bit, position) do
    if bit == 1 do
      {value ||| (1 <<< position), max(size, position + 1)}
    else
      # 1's complement for bitwise not
      {value &&& elem(negate({1 <<< position, position + 1}), 0), max(size, position + 1)}
    end
  end

  @doc """
    Read bit at position
  """
  def getBitAt({value, _}, position) do
    (value >>> position) &&& 1
  end

  @doc """
    Convert a boolean value to bit
  """
  def boolToBit(value) when is_boolean(value)do
    if value do
      1
    else
      0
    end
  end

  @doc """
    Bitwise and on the structure
  """
  def bitAnd({f1, s1}, {f2, s2}) do
    {f1 &&& f2, max(s1, s2)}
  end

  @doc """
    Returns a list of index of bit having 1 value
  """
  def listOfIndexOfOne(bits) do
    listOfIndexOf(bits, 1)
  end

  @doc """
    Returns a list of index of bit having 0 value
  """
  def listOfIndexOfZero(bits) do
    listOfIndexOf(bits, 0)
  end

  @doc """
    Returns a list of index of bit having bit value
  """
  def listOfIndexOf({key, size}, bitToCheck) do
      #listOfIndexOf(key, bitToCheck, 0, [])
      {_,_, ret} = Enum.reduce_while(1..size, {key, 0, []},
          fn (_, {key, index, acc} = input) ->
            if key == 0 do
              {:halt, input}
            else
              val = key &&& 1
              updateKey = key >>> 1

              ret = if(val == bitToCheck, do: [index | acc], else: acc)              

              {:cont, {updateKey, index + 1, ret}}
            end
          end)
      ret
  end

  @doc """
    Print a string of bit representing the key
  """
  def dumpBits(key) do
    IO.puts(dumpBitsStr(key))
  end

  @doc """
    Generate a string of bit representing the key
  """
  def dumpBitsStr(key) when is_integer(key) do
    "Key: " <> inspect(Integer.digits(key, 2))
  end

  @doc """
    Generate a string of bit representing the key
  """
  def dumpBitsStr({key, size}) do
    "Key(" <> Integer.to_string(size) <> "): "
           <> inspect(Integer.digits(key, 2))
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

  ## Internal recursive function that allows list of index generation from key
  defp listOfIndexOf(key, bitToCheck, index, acc) do
    if key == 0 do
      acc
    else
      val = key &&& 1
      listOfIndexOf(key >>> 1, bitToCheck, index + 1,
                            if(val == bitToCheck,
                               do: [index | acc],
                               else: acc))
    end
  end
end
