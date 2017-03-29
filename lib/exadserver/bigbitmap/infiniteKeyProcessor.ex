defmodule ExAdServer.BigBitmap.InfiniteKeyProcessor do
  @moduledoc """
  Infinite key processor implementation.
  """
  @compile {:parse_transform, :ms_transform}

  @behaviour ExAdServer.BigBitmap.BehaviorKeysProcessor

  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  ## Behaviour Callbacks

  def generateAndStoreIndex(_adConf, {indexName, _indexMetadata}, indexes) do
    Map.put(indexes, indexName, nil)
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
