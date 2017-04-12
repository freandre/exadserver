defmodule ExAdServer.Indexes.FiniteKeyProcessor do
  @moduledoc """
  Finite key processor implementation.
  """

  @behaviour ExAdServer.Indexes.BehaviorKeysProcessor

  require Logger
  import ExAdServer.Utils.Storage
  alias ExAdServer.Utils.BitUtils
  alias :ets, as: ETS

  ## Behaviour Callbacks

  def generateMetadata(targeterMetada) do
    val = targeterMetada
    |> Enum.filter_map(fn ({_, v}) -> v["type"] == "finite" end,
                       fn ({k, v}) -> {k, updateDistinctValues(v)} end)
    |> Enum.reduce(%{}, fn ({k, v}, acc) ->
                          createStore(getIxAtom(k))
                          Map.put(acc, k, v)
                        end)

    ret = [{"finite", ExAdServer.Indexes.FiniteKeyProcessor, val}]

    Logger.debug fn -> "[FiniteKeyProcessor] - Exiting generateMetadata returning:\n#{inspect(ret)}" end

    ret
  end

  def generateAndStoreIndex(adData, {_, indexMetadata}) do
    Enum.each(indexMetadata,
              fn(indexData) ->
                generateAndStoreUniqueIndex(adData, indexData)
              end)
  end

  def findInIndex(adRequest, {_, indexMetadata}, acc) do
    Logger.debug fn -> "[FiniteKeyProcessor] - findInIndex request:\n#{inspect(adRequest)}" end

    ret = indexMetadata
          |> Enum.reduce_while(:first,
                    fn({index_name, _} = val, acc) ->
                      data = findInUniqueIndex(adRequest, val, acc)
                      Logger.debug fn -> "> #{index_name} => #{inspect(decodebitField(data, :bit_ix_to_ads_store))}" end
                      checkMainStopCondition(data)
                    end)
          |> decodebitField(:bit_ix_to_ads_store)

    buildFindInIndex(acc, ret)
  end

  ## Private functions

  ## Update the metadata with an unknown distinct value
  defp updateDistinctValues(v) do
    Map.put(v, "distinctvalues", ["unknown" | v["distinctvalues"]])
  end

  ## Deal with the processing of only one index
  defp generateAndStoreUniqueIndex({adConf, bitIndex}, {indexName, indexMetadata}) do
    Logger.debug "[FiniteKeyProcessor] - generateAndStoreUniqueIndex: #{indexName}"
    Logger.debug fn ->  "> Conf:\n#{inspect(adConf["targeting"][indexName])}" end

    distinct_values = indexMetadata["distinctvalues"]
    values_to_store = adConf["targeting"][indexName]
                      |> getValuesToStore(distinct_values)
    Logger.debug fn -> "> Distinct values:\n#{inspect(distinct_values)}" end
    Logger.debug fn -> "> Values to store:\n#{inspect(values_to_store)}" end

    Enum.each(values_to_store, &(generateAndStoreValue(getIxAtom(indexName), &1, bitIndex)))
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
    data = store
           |> getStoredValue(distinctValue)
           |> BitUtils.setBitAt(1, bitIndex)
    Logger.debug fn -> "[FiniteKeyProcessor] - generateAndStoreValue #{distinctValue}:\n#{BitUtils.dumpBitsStr(data)}" end
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
  defp findInUniqueIndex(request, {indexName, _}, acc) do
    value = getValue(request[indexName])
    [{^value, data}] = ETS.lookup(getIxAtom(indexName), value)

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
  #defp decodebitFieldParallel({_, size} = data, ixToAdIDStore) do
  #  BitUtils.splitBits(data, size) # for now do not split anything
  #  |> Enum.map(fn({data, range}) ->
  #                Task.async(fn ->
  #                             BitUtils.listOfIndexOfOne(data, range)
  #                           end)
  #              end)
  #  |> Enum.map(&(Task.await(&1)))
  #  |> Enum.reduce([], &(&1 ++ &2))
  #  |> Enum.reduce(MapSet.new,
  #           fn(index, acc) ->
  #             [{^index, ad_id}] = ETS.lookup(ixToAdIDStore, index)
  #             MapSet.put(acc, ad_id)
  #           end)
  #end
  defp decodebitField(data, ixToAdIDStore) do
    data
    |> BitUtils.listOfIndexOfOne
    |> Enum.reduce(MapSet.new,
             fn(index, acc) ->
               [{^index, ad_id}] = ETS.lookup(ixToAdIDStore, index)
               MapSet.put(acc, ad_id)
             end)
  end
end
