defmodule ExAdServer.Bitmap.InfiniteKeyProcessor do
  @moduledoc """
  Infinite key processor implementation.
  """

  @behaviour ExAdServer.Config.BehaviorKeysProcessor

  ## Behaviour Callbacks

  def getIndexKeyForStorage(adConf, indexName,  _indexMetadata) do
    targeter = adConf["targeting"][indexName]["data"]
    inclusive = adConf["targeting"][indexName]["inclusive"]

    Enum.map(targeter, &({{inclusive, &1}, adConf["adid"]}))
  end

  def findInIndex(ad, {indexName, indexMetadata}, indexes) do
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
