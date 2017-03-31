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

  def findInIndex(ad, {_, finiteMetadata}, indexes, accumulator) do
    {store, _indexes} = getStore("finite", indexes)

    {key, _size} = Enum.reduce(finiteMetadata, {0, 0},
                fn ({indexName, indexMetadata}, acc) ->
                  encodeKey(ad[indexName],
                             indexMetadata["distinctvalues"])
                  |> aggregateAccumulators(acc)
                end)

    # foldl seems slower finally
    #ret = ETS.foldl(
    #          fn({stored_key, id}, acc) ->
    #            if ((stored_key &&& key) == key) do
    #              MapSet.put(acc, id)
    #            else
    #              acc
    #            end
    #          end,
    #          MapSet.new, store)

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
    inclusive = targeter["inclusive"]
    cond do
      # +1 for unknown value
      # let s fix the "unknown value" at the very begining of the bit field
    targeter == nil -> generateAllWithOne(length(metadata) + 1)
    targeter["data"] == ["all"] and inclusive -> generateAllWithOne(length(metadata) + 1)
    targeter["data"] == ["all"] and inclusive == false ->
                                 {1 <<< length(metadata), length(metadata) + 1}

    true -> metadata
            |> Enum.reduce({0, 1}, # not unknown so 0 at index 1
                     &(if &1 in targeter["data"] do
                         addOne(&2)
                       else
                         addZero(&2)
                       end))
            |> conditionalNot(inclusive == false)
            |> setBitAt(inclusive == false, length(metadata))
    end
  end

  ## Generate a key from ad value, the first argument is the ad value to encode
  ## the second the associated distinct values for this attribute
  defp encodeKey(adValue, metadata) do
    if adValue == nil do
      {1 <<< length(metadata), length(metadata) + 1}
    else
      Enum.reduce(metadata, {0, 1},
                  &(if &1 == adValue do
                      addOne(&2)
                    else
                      addZero(&2)
                    end))
    end
  end
end
