defmodule ExAdServer.Utils.BitUtils do
  @moduledoc """
  Bit manipulation utility module.
  """
  @compile :native

  use Bitwise

  @bit_one 1
  @bit_zero 0

  @doc """
  Get a new bit structure : {data, size}
  """
  def new(), do: {0, 0}

  @doc """
  Generate a tuple {data, size} of values of size size with 1
  """
  def generateAllWithOne(size) when size >= 0, do: generateOneBits(size, new())

  @doc """
  Generate a tuple {data, size} of values of size size with 0
  """
  def generateAllWithZero(size) when size >= 0, do: {@bit_zero, size}

  @doc """
  Add a 1 bit
  """
  def addOne({data, size}), do: {:erlang.bor(:erlang.bsl(data, 1), @bit_one), size + 1}

  @doc """
  Add a 0 bit
  """
  def addZero({data, size}), do: {:erlang.bsl(data, 1), size + 1}

  @doc """
    Put a specific bit at position
  """
  def setBitAt({data, size}, @bit_one, position),do: {:erlang.bor(data, :erlang.bsl(1, position)), :erlang.max(size, position + 1)}
  def setBitAt({_, size} = val, @bit_zero, position) when position >= size, do: val
  def setBitAt({data, size} = val, @bit_zero, position) do
    head = :erlang.bsl(:erlang.bsr(data, position + 1), position + 1)
    {tail, _} = bitAnd(val, generateAllWithOne(position))
    {:erlang.bor(head, tail), size}
  end

  @doc """
    Read bit at position
  """
  def getBitAt({data, _size}, position) do
    :erlang.band(data, :erlang.bsl(1, position))
  end

  @doc """
    Convert a boolean value to bit
  """
  def boolToBit(true), do: @bit_one
  def boolToBit(false), do: @bit_zero

  @doc """
    Bitwise and on the bit structure
  """
  def bitAnd({data1, sz1}, {data2, sz2}), do: {:erlang.band(data1, data2), :erlang.min(sz1, sz2)}

  @doc """
    Returns a list of index (begining at indexPos) of bit having 1 value
  """
  def listOfIndexOfOne(bits, beginingPos \\ 0), do: listOfIndexOf(bits, @bit_one, beginingPos)

  @doc """
    Returns a list of index (begining at indexPos) of bit having 0 value
  """
  def listOfIndexOfZero(bits, beginingPos \\ 0), do: listOfIndexOf(bits, @bit_zero, beginingPos)

  @doc """
    Returns a list of index (begining at indexPos) of bit having bit value
  """
  def listOfIndexOf({data, size}, bit, beginingPos \\ 0) do
    listOfIndexOf(<<data::size(size)>>, bit, size - 1, beginingPos, [])
  end

  @doc """
    Split a bits structure in several block of size blockSize bits
    Returns a list of {bitStruct, beginingIndex}
  """
  def splitBits(bits, blockSize), do: splitBits(bits, generateAllWithOne(blockSize), blockSize, 0, [])

  @doc """
    Print a string of bit representing the key
  """
  def dumpBits(bits) do
    IO.puts(dumpBitsStr(bits))
  end

  @doc """
    Generate a string of bit representing the key
  """
  def dumpBitsStr({data, sz}) do
    "Key(" <> Integer.to_string(sz) <> "): "
           <> inspect(Integer.digits(data, 2))
  end

  ## Private functions

  ## Generate a structure filled up with bit
  defp generateOneBits(size, acc) when size > 0, do: generateOneBits(size - 1, addOne(acc))
  defp generateOneBits(_, acc), do: acc

  ## Returns a list of index representing the bits set
  defp listOfIndexOf(<<>>, _, _, _, acc), do: acc
  defp listOfIndexOf(<<bit::integer-size(1), rest::bitstring>>, bit, index, start_index, acc) do
    listOfIndexOf(rest, bit, index - 1, start_index, [start_index + index | acc])
  end
  defp listOfIndexOf(<<_::integer-size(1), rest::bitstring>>, bit, index, start_index, acc) do
    listOfIndexOf(rest, bit, index - 1, start_index, acc)
  end

  ## Recursively split integer in chunks
  defp splitBits({_, size}, _, _, _, acc) when size == 0, do: acc
  defp splitBits({data, size} = bits, mask, blockSize, blockNumber, acc) when size >= blockSize do
    splitBits({data >>> blockSize, size - blockSize}, mask, blockSize,
        blockNumber + 1, [{bitAnd(bits, mask), blockSize * blockNumber} | acc])
  end
  defp splitBits({_, size} = bits, mask, blockSize, blockNumber, acc) when size < blockSize do
    splitBits(new(), mask, blockSize, blockNumber + 1, [{bitAnd(bits, mask), blockSize * blockNumber} | acc])
  end
end
