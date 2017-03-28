defmodule ExAdServer.Bitmap.InfiniteKeyProcessor do
  @moduledoc """
  Infinite key processor implementation.
  """
  @compile {:parse_transform, :ms_transform}

  @behaviour ExAdServer.Config.BehaviorKeysProcessor

  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  ## Behaviour Callbacks

  def generateAndStoreIndex(adConf, {indexName, _indexMetadata}, indexes) do
    {store, indexes} = getStore(indexName, indexes)

    targeter = adConf["targeting"][indexName]["data"]
    inclusive = adConf["targeting"][indexName]["inclusive"]

    ETS.insert(store, Enum.map(targeter, &({{inclusive, &1}, adConf["adid"]})))
    indexes
  end

  def findInIndex(ad, {indexName, _indexMetadata}, indexes) do
    store = getStore(indexName, indexes)
    value = ad[indexName]

    included = MapSet.new(ETS.select(store,
                 ETS.fun2ms(fn({{inclusive, storedValue}, id})
                              when
                              (inclusive == true and
                                    (storedValue == "all" or storedValue == value))
                                or (inclusive == false and storedValue != value)
                              ->
                           id
                 end)))
    excluded = MapSet.new(ETS.select(store,
                 ETS.fun2ms(fn({{inclusive, storedValue}, id})
                              when
                              inclusive == false and storedValue == value
                              ->
                           id
                 end)))
    MapSet.difference(included, excluded)
  end
end
