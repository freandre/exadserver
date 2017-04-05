defmodule ExAdServer.TypedSet.FiniteKeyProcessor do
  @moduledoc """
  Finite key processor implementation.
  """

  @behaviour ExAdServer.TypedSet.BehaviorKeysProcessor

  require Logger
  import ExAdServer.Utils.Storage
  alias ExAdServer.Utils.BitUtils
  alias :ets, as: ETS

  ## Behaviour Callbacks

  def generateMetadata(targeterMetada) do
    val = targeterMetada
    |> Enum.filter_map(fn ({_, v}) -> v["type"] == "finite" end,
                       fn ({k, v}) -> {k, updateDistinctValues(v)} end)
    |> Enum.reduce(%{}, fn ({k, v}, acc) -> Map.put(acc, k, v) end)
    ret = [{"finite", ExAdServer.TypedSet.FiniteKeyProcessor, val}]

    Logger.debug fn -> "[finiteKeyProcessor] - Exiting generateMetadata returning:\n#{inspect(ret)}" end

    ret
  end

  def generateAndStoreIndex(adData, {_, indexMetadata}, indexes) do
    Enum.reduce(indexMetadata, indexes,
                fn(indexData, acc) ->
                  generateAndStoreUniqueIndex(adData, indexData, acc)
                end)
  end

  def findInIndex(adRequest, {_, indexMetadata}, indexes, acc) do
    {ix_ads_store, indexes} = getStore("bitIxToAdsStore", indexes)

    Logger.debug fn -> "[finiteKeyProcessor] - findInIndex request:\n#{inspect(adRequest)}" end

    ret = Enum.reduce_while(indexMetadata, :first,
                    fn({indexName, _} = val, acc) ->
                      data = findInUniqueIndex(adRequest,
                                        val, indexes, acc)
                      Logger.debug fn -> "#{indexName} => #{inspect(decodebitField(data, ix_ads_store))}" end
                      checkMainStopCondition(data)
                    end)
    |> decodebitField(ix_ads_store)

    buildFindInIndex(acc, ret)
  end

  ## Private functions

  ## Update the metadata with an unknown distinct value
  defp updateDistinctValues(v) do
    Map.put(v, "distinctvalues", ["unknown" | v["distinctvalues"]])
  end

  ## Deal with the processing of only one index
  defp generateAndStoreUniqueIndex({adConf, bitIndex}, {indexName, indexMetadata}, indexes) do
    Logger.debug "[finiteKeyProcessor] - generateAndStoreUniqueIndex: #{indexName}"
    Logger.debug fn ->  "conf:\n#{inspect(adConf["targeting"][indexName])}" end

    {store, indexes} = getStore(indexName, indexes)
    distinct_values = indexMetadata["distinctvalues"]
    values_to_store = adConf["targeting"][indexName]
                      |> getValuesToStore(distinct_values)
    Logger.debug fn -> "distinct values:\n#{inspect(distinct_values)}" end
    Logger.debug fn -> "Values to store:\n#{inspect(values_to_store)}" end

    Enum.each(values_to_store, &(generateAndStoreValue(store, &1, bitIndex)))
    indexes
  end

  ## Select matching value to store data depending on conf values and inclusive tag
  defp getValuesToStore(confValues, distinctValues) do
    inclusive = confValues["inclusive"]
    cond do
      inclusive == nil or (inclusive and confValues["data"] == ["all"])
                    -> distinctValues
      inclusive == false and confValues["data"] == ["all"] -> ["unknown"]
      inclusive -> confValues["data"]
      inclusive == false -> (distinctValues -- confValues["data"]) -- ["unknown"]
    end
  end

  ## Given a key of distinct values, check if it's part of values to store
  ## set the bit of retrived bitmap at index
  defp generateAndStoreValue(store, distinctValue, bitIndex) do
    data = getStoredValue(store, distinctValue)
           |> BitUtils.setBitAt(1, bitIndex)
    Logger.debug fn -> "[finiteKeyProcessor] - generateAndStoreValue #{distinctValue}:\n#{BitUtils.dumpBitsStr(data)}" end
    ETS.insert(store, {distinctValue,  data})
  end

  ## Get a stored value or initialize it
  defp getStoredValue(store, id) do
    data = ETS.lookup(store, id)
    returnOrInitValue(data)
  end

  ## If data is empty, initialize it
  defp returnOrInitValue([]), do: BitUtils.new
  defp returnOrInitValue(data), do: elem(Enum.at(data, 0), 1)

  ## Find data in a unique index
  defp findInUniqueIndex(request, {indexName, _}, indexes, acc) do
    {store, _indexes} = getStore(indexName, indexes)

    value = getValue(request[indexName])
    [{^value, data}] = ETS.lookup(store, value)

    buildFindInUniqueIndex(acc, data)
  end

  ## Shall we stop to loop
  defp checkMainStopCondition(data) when elem(data, 0) == 0, do: {:halt, data}
  defp checkMainStopCondition(data), do: {:cont, data}

  ## Are we in the first iteration ?
  defp buildFindInIndex(:first, data), do: data
  defp buildFindInIndex(acc, data), do: MapSet.intersection(data, acc)

  ## Are we in the first iteration ?
  defp buildFindInUniqueIndex(:first, data), do: data
  defp buildFindInUniqueIndex(acc, data), do: BitUtils.bitAnd(data, acc)

  ## Simple filter to handle unknown value
  defp getValue(nil), do: "unknown"
  defp getValue(requestValue), do: requestValue

  ## Decode a bitfield to a list of ad id
  defp decodebitField(data, ixToAdIDStore) do
    BitUtils.listOfIndexOfOne(data)
    |> Enum.reduce(MapSet.new,
             fn(index, acc) ->
               [{^index, adId}] = ETS.lookup(ixToAdIDStore, index)
               MapSet.put(acc, adId)
             end)
  end
end
