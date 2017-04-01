defmodule ExAdServer.TypedSet.InfiniteKeyProcessor do
  @moduledoc """
  Infinite key processor implementation.
  """
  @compile {:parse_transform, :ms_transform}

  @behaviour ExAdServer.Bitmap.BehaviorKeysProcessor

  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  ## Behaviour Callbacks

  def generateAndStoreIndex({adConf, _bitIndex}, {indexName, _indexMetadata}, indexes) do
    {store, indexes} = getBagStore(indexName, indexes)

    targeter = adConf["targeting"][indexName]["data"]
    inclusive = adConf["targeting"][indexName]["inclusive"]

    ETS.insert(store, Enum.map(targeter, &({{inclusive, &1}, adConf["adid"]})))
    indexes
  end

  def findInIndex(ad, {indexName, _indexMetadata}, indexes) do
    {store, _indexes} = getBagStore(indexName, indexes)
    value = ad[indexName]

    if value == nil do
      MapSet.new(ETS.select(store,
                            ETS.fun2ms(fn({{_, storedValue}, id})
                                       when
                                         storedValue == "all"
                                       ->
                                         id
                                       end)))
    else
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
end
