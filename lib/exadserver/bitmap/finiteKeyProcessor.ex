defmodule ExAdServer.Bitmap.FiniteKeyProcessor do
  @moduledoc """
  Finite key processor implementation.
  """
  @compile {:parse_transform, :ms_transform}

  use Bitwise

  @behaviour ExAdServer.Bitmap.BehaviorKeysProcessor

  import ExAdServer.Utils.Storage
  import ExAdServer.Utils.BitUtils
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
end
