defmodule ExAdServer.BigBitmap.InfiniteKeyProcessor do
  @moduledoc """
  Infinite key processor implementation.
  """
  @compile {:parse_transform, :ms_transform}

  @behaviour ExAdServer.BigBitmap.BehaviorKeysProcessor

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

  def findInIndex(adRequest, {indexName, _indexMetadata}, indexes, accumulator) do
    {ads_store, _indexes} = getStore("adsStore", indexes)

    Enum.reduce(accumulator, MapSet.new,
                fn(ad_id, acc) ->
                  [{^ad_id, ad_conf}] = ETS.lookup(ads_store, ad_id)
                    conf_values = ad_conf["targeting"][indexName]
                    conf_inclusive = conf_values["inclusive"]
                    conf_data = conf_values["data"]

                    if conf_inclusive == false and adRequest[indexName] in conf_data do
                      acc
                    else
                      MapSet.put(acc, ad_id)
                    end
                end)
  end
end
