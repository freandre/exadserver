defmodule ExAdServer.BigBitmap.FiniteKeyProcessor do
  @moduledoc """
  Finite key processor implementation.
  """
  @compile {:parse_transform, :ms_transform}

  use Bitwise

  @behaviour ExAdServer.BigBitmap.BehaviorKeysProcessor

  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  ## Behaviour Callbacks
  def generateAndStoreIndex(adConf, {indexName, indexMetadata}, indexes) do
    {store, indexes} = getStore(indexName, indexes)

    {key, _size} = encodeSingleTarget(adConf["targeting"][indexName],
                                      indexMetadata["distinctvalues"])

    ETS.insert(store, {key, adConf["adid"]})
    indexes
  end

  def findInIndex(ad, {indexName, indexMetadata}, indexes) do
    {store, _indexes} = getStore(indexName, indexes)

    {key, _size} = encodeKey(ad[indexName],
                             indexMetadata["distinctvalues"])

    MapSet.new(ETS.select(store,
                          ETS.fun2ms(fn({stored_key, id})
                              when
                                ((stored_key &&& key) == key)
                                or ((stored_key ||| key) == stored_key)
                              ->
                                id
                              end)))
  end

  ## Private functions

  ## Encode a single target, the first argument is one of the targeting attribute
  ## the second the associated distinct values for this attribute, the last indicates
  ## the behavior if targeter is unknown
  defp encodeSingleTarget(targeter, metadata) do
    cond do
    targeter == nil -> generateAllWithOne(length(metadata))
    targeter["data"] == ["all"] -> metadata
                                 |> length()
                                 |> generateAllWithOne()
                                 |> excludeIfNeeded(targeter["inclusive"])
    true -> metadata
            |> Enum.reduce({0, 0},
                     &(if &1 in targeter["data"] do
                         addOne(&2)
                       else
                         addZero(&2)
                       end))
            |> excludeIfNeeded(targeter["inclusive"])
    end
  end

  ## Generate a key from ad value, the first argument is the ad value to encode
  ## the second the associated distinct values for this attribute
  defp encodeKey(adValue, metadata) do
    if adValue == nil do
      generateAllWithZero(length(metadata))
    else
      Enum.reduce(metadata, {0, 0},
                  &(if &1 == adValue do
                      addOne(&2)
                    else
                      addZero(&2)
                    end))
    end
  end

  ## Generate a tuple {data, size} of values of size size with 1
  defp generateAllWithOne(size) when size >= 0 do
    generateAll(size, true)
  end

  ## Generate a tuple {data, size} of values of size size with 0
  defp generateAllWithZero(size) when size >= 0 do
    generateAll(size, false)
  end

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

  ## Negate the data of the tuple is inclusive is false
  defp excludeIfNeeded({data, size} = value, inclusive) do
    case inclusive do
      false -> {~~~data, size}
      _ -> value
    end
  end

  ## Add a 1 bit
  defp addOne({data, size}) do
    {(data <<< 1) ||| 1, size + 1}
  end

  ## Add a 0 bit
  defp addZero({data, size}) do
    {(data <<< 1), size + 1}
  end
end
