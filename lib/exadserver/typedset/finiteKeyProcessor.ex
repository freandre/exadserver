defmodule ExAdServer.TypedSet.FiniteKeyProcessor do
  @moduledoc """
  Finite key processor implementation.
  """
  @compile {:parse_transform, :ms_transform}

  @behaviour ExAdServer.Bitmap.BehaviorKeysProcessor

  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  ## Behaviour Callbacks
  def generateAndStoreIndex(adConf, {indexName, indexMetadata}, indexes) do
    {store, indexes} = getStore(indexName, indexes)

    adConf["targeting"][indexName]
    |> getValuesToStore(indexMetadata["distinctvalues"])
    |> Enum.each(&(ETS.insert(store, {&1, adConf["adid"]})))

    indexes
  end

  def findInIndex(request, {indexName, _}, indexes) do
    {store, _indexes} = getStore(indexName, indexes)

    value = getValue(request[indexName])
    ETS.lookup(store, value)
    |> Enum.map(fn ({_, val}) -> val end)
    |> MapSet.new
  end

  ## Private functions

  ## Select matching value to store data depending on conf values and inclusive tag
  defp getValuesToStore(confValues, distinctValues) do
    inclusive = confValues["inclusive"]
    cond do
      inclusive == nil -> ["unknown" | distinctValues]
      inclusive and confValues["data"] == ["all"] -> ["unknown" | distinctValues]
      inclusive == false and confValues["data"] == ["all"] -> ["unknown"]
      inclusive -> confValues["data"]
      inclusive == false -> distinctValues -- confValues["data"]
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
end
