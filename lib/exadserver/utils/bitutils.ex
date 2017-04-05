defmodule ExAdServer.Utils.BitUtils do
  @moduledoc """
  Bit manipulation utility module.
  """

  use Bitwise

  @bit_one <<1::integer-size(1)>>
  @bit_zero <<0::integer-size(1)>>

  @doc """
  Get a new bit structure
  """
  def new, do: <<>>

  @doc """
  Generate a tuple {data, size} of values of size size with 1
  """
  def generateAllWithOne(size) when size >= 0, do: generateSizeBits(size, 1, <<>>)

  @doc """
  Generate a tuple {data, size} of values of size size with 0
  """
  def generateAllWithZero(size) when size >= 0, do: generateSizeBits(size, 0, <<>>)

  @doc """
  Add a 1 bit
  """
  def addOne(data), do: <<data::bitstring, @bit_one::bitstring>>

  @doc """
  Add a 0 bit
  """
  def addZero(data), do: <<data::bitstring, @bit_zero::bitstring>>

  @doc """
    Put a specific bit at position
  """
  def setBitAt(bits, bit, position) when bit_size(bits) >= position + 1 do
    sz_head = bit_size(bits) - (position + 1)
    <<head::size(sz_head), _::size(1), tail::bitstring>> = bits
    <<head::size(sz_head), bit::size(1), tail::bitstring>>
  end
  def setBitAt(bits, bit, position) do
    filler_sz = position - bit_size(bits)
     <<bit::size(1), 0::size(filler_sz), bits::bitstring>>
  end

  @doc """
    Read bit at position
  """
  def getBitAt(bits, position) do
    sz_head = bit_size(bits) - (position + 1)
    <<_::size(sz_head), ret::size(1), _::bitstring>> = bits
    ret
  end

  @doc """
    Convert a boolean value to bit
  """
  def boolToBit(true), do: @bit_one
  def boolToBit(false), do: @bit_zero

  @doc """
    Return firt n low order bits from a binary
  """
  def getLowOrderBits(bits, nbBits) do
    sz = bit_size(bits) - nbBits
    <<_::size(sz), ret::size(nbBits)>> = bits
    <<ret::size(nbBits)>>
  end

  @doc """
    Bitwise and on the bitstring
  """
  def bitAnd(bits1, bits2) do
    sz = bit_size(bits1)
    <<val1::size(sz)>> = bits1
    sz = bit_size(bits2)
    <<val2::size(sz)>> = bits2

    :binary.encode_unsigned(val1 &&& val2)
  end

  @doc """
    Returns a list of index of bit having 1 value
  """
  def listOfIndexOfOne(bits), do: listOfIndexOf(1, bits)

  @doc """
    Returns a list of index of bit having 0 value
  """
  def listOfIndexOfZero(bits), do: listOfIndexOf(0, bits)

  @doc """
    Returns a list of index of bit having bit value
  """
  def listOfIndexOf(bit, bits), do: listOfIndexOf(bit, bits, bit_size(bits) - 1, [])

  @doc """
    Print a string of bit representing the key
  """
  def dumpBits(key) do
    IO.puts(dumpBitsStr(key))
  end

  @doc """
    Generate a string of bit representing the key
  """
  def dumpBitsStr(bits) do
    "Key(" <> Integer.to_string(bit_size(bits)) <> "): "
           <> inspect(getBitsList(bits))
  end

  ## Private functions

  ## Returns a list of bit. Not sure about performances so use with care
  defp getBitsList(bits) do
    sz = bit_size(bits)
    <<val::size(sz)>> = bits
    Integer.digits(val, 2)
  end

  ## Generate a binary filled up with bit
  defp generateSizeBits(size, bit, acc) when size > 0, do: generateSizeBits(size - 1, bit, <<bit::integer-size(1), acc::bitstring>>)
  defp generateSizeBits(_, _, acc), do: acc

  ## Returns a list of index representing the bits set
  defp listOfIndexOf(_, <<>>, _index, acc), do: acc
  defp listOfIndexOf(bit, <<bit::integer-size(1), rest::bitstring>>, index, acc), do: listOfIndexOf(bit, rest, index - 1, [index | acc])
  defp listOfIndexOf(bit, <<_::integer-size(1), rest::bitstring>>, index, acc), do: listOfIndexOf(bit, rest, index - 1, acc)

end
