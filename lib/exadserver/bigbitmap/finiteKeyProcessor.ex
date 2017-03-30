defmodule ExAdServer.BigBitmap.FiniteKeyProcessor do
  @moduledoc """
  Finite key processor implementation.
  """
  @compile {:parse_transform, :ms_transform}

  use Bitwise

  @behaviour ExAdServer.BigBitmap.BehaviorKeysProcessor

  import ExAdServer.Utils.Storage
  import ExAdServer.Utils.BitUtils
  alias :ets, as: ETS

  ## Behaviour Callbacks
  def generateAndStoreIndex(adConf, {_, finiteMetadata}, indexes) do
    {store, indexes} = getStore("finite", indexes)

    {key, _size} = Enum.reduce(finiteMetadata, {0, 0},
             fn({indexName, indexMetadata}, acc) ->
               encodeSingleTarget(adConf["targeting"][indexName],
                                                 indexMetadata["distinctvalues"])
                              |> aggregateAccumulators(acc)
             end)

    ETS.insert(store, {key, adConf["adid"]})
    indexes
  end

  def findInIndex(ad, {indexName, indexMetadata}, indexes, accumulator) do
    {store, _indexes} = getStore(indexName, indexes)

    #TODO implement encode  / aggregate
    {key, _size} = encodeKey(ad[indexName],
                             indexMetadata["distinctvalues"])

    ret = MapSet.new(ETS.select(store,
                          ETS.fun2ms(fn({stored_key, id})
                              when
                                ((stored_key &&& key) == key)
                              ->
                                id
                              end)))
    if accumulator == :first do
      ret
    else
      MapSet.intersection(accumulator, ret)
    end
  end

  ## Private functions

  ## Encode a single target, the first argument is one of the targeting attribute
  ## the second the associated distinct values for this attribute, the last indicates
  ## the behavior if targeter is unknown
  defp encodeSingleTarget(targeter, metadata) do
    cond do
      # +1 for unknown value
    targeter == nil -> generateAllWithOne(length(metadata) + 1)
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
end
