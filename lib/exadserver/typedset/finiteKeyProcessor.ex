defmodule ExAdServer.TypedSet.FiniteKeyProcessor do
  @moduledoc """
  Finite key processor implementation.
  """

  @behaviour ExAdServer.TypedSet.BehaviorKeysProcessor

  import ExAdServer.Utils.BitUtils
  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  ## Behaviour Callbacks

  def generateMetadata(targeterMetada) do
    val = targeterMetada
    |> Enum.filter_map(fn ({_, v}) -> v["type"] == "finite" end,
                       fn ({k, v}) -> {k, getMappers(v)} end)
    |> Enum.reduce(%{}, fn ({k, v}, acc) -> Map.put(acc, k, v) end)
    [{"finite", ExAdServer.TypedSet.FiniteKeyProcessor, val}]
  end

  def generateAndStoreIndex(adData, {_, indexMetadata}, indexes) do
    Enum.reduce(indexMetadata, indexes,
                fn(indexData, acc) ->
                  generateAndStoreUniqueIndex(adData, indexData, acc)
                end)
  end

  def findInIndex(adRequest, {_, indexMetadata}, indexes, acc) do
    {ix_ads_store, indexes} = getStore("ixToAdsStore", indexes)

    ret = Enum.reduce_while(indexMetadata, :first,
                    fn({indexName, indexMetaData}, acc) ->
                      data = findInUniqueIndex(adRequest,
                                        {indexName, indexMetaData}, indexes, acc)
                      if elem(data, 0) == 0 do
                        {:halt, data}
                      else
                        {:cont, data}
                      end
                    end)
    |> decodebitField(ix_ads_store)

    if acc == :first do
      ret
    else
      MapSet.intersection(ret, acc)
    end
  end

  ## Private functions

  ## Update the metadata with and index number to data and its reverse mapper
  defp getMappers(v) do
    {data_to_ix, _} =
      Enum.reduce(v["distinctvalues"], {%{"unknown" => 0}, 1},
                  fn (val, {data_to_ix, index}) ->
                    {Map.put(data_to_ix, val, index),
                     index + 1}
                  end)
    v
    |> Map.put("datatoix", data_to_ix)
  end

  ## Deal with the processing of only one index
  defp generateAndStoreUniqueIndex({adConf, bitIndex}, {indexName, indexMetadata}, indexes) do
    {store, indexes} = getStore(indexName, indexes)
    data_to_ix = indexMetadata["datatoix"]
    values_to_store = adConf["targeting"][indexName]
                      |> getValuesToStore(data_to_ix)
    Enum.each(data_to_ix,
            fn (val) ->
              generateAndStoreValue(store, val, values_to_store, bitIndex)
            end)
    indexes
  end

  ## Select matching value to store data depending on conf values and inclusive tag
  defp getValuesToStore(confValues, dataToIx) do
    inclusive = confValues["inclusive"]
    cond do
      inclusive == nil or (inclusive and confValues["data"] == ["all"]) ->
                   Enum.map(dataToIx, fn ({value, _}) -> value end)
      inclusive == false and confValues["data"] == ["all"] -> ["unknown"]
      inclusive -> confValues["data"]
      inclusive == false -> Enum.map(dataToIx, fn ({value, _}) -> value end)  -- confValues["data"]
    end
  end

  ## Given a key of distinct values, check if it's part of values to store
  ## set the bit of retrived bitmap at index
  defp generateAndStoreValue(store, {data_value, data_index}, keysToStore, bitIndex) do
    data = getStoredValue(store, data_index)
           |> setBitAt(boolToBit(data_value in keysToStore), bitIndex)
    ETS.insert(store, {data_index,  data})
  end

  ## Get a stored value or initialize it
  defp getStoredValue(store, id) do
    data = ETS.lookup(store, id)

    if data == [] do
      {0, 0}
    else
      elem(Enum.at(data, 0), 1)
    end
  end

  ## Find data in a unique index
  defp findInUniqueIndex(request, {indexName, indexMedata}, indexes, acc) do
    {store, _indexes} = getStore(indexName, indexes)

    value = getValue(request[indexName])
    value = indexMedata["datatoix"][value]
    [{^value, data}] = ETS.lookup(store, value)

    if :first == acc do
      data
    else
      bitAnd(data, acc)
    end
  end

  ## Simple filter to handle unknown value
  defp getValue(requestValue) do
    if requestValue == nil do
      "unknown"
    else
      requestValue
    end
  end

  ## Decode a bitfield to a list of ad id
  defp decodebitField({_, size} = data, ixToAdIDStore) do
    decodebitField(data, size - 1, [])
    |> Enum.reduce(MapSet.new,
             fn(index, acc) ->
               [{^index, adId}] = ETS.lookup(ixToAdIDStore, index)
               MapSet.put(acc, adId)
             end)
  end

  defp decodebitField(data, index, ret) when index >= 0 do
    bit = getBitAt(data, index)
    decodebitField(data, index - 1, updateRet(ret, bit, index))
  end

  defp decodebitField(_, index, ret) when index < 0 do
    ret
  end

  ## Update list of index according to bit
  defp updateRet(ret, bit, index) do
    if bit == 1 do
      [index | ret]
    else
      ret
    end
  end
end
