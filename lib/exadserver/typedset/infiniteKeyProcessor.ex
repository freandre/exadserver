defmodule ExAdServer.TypedSet.InfiniteKeyProcessor do
  @moduledoc """
  Infinite key processor implementation.
  """
  @compile {:parse_transform, :ms_transform}

  @behaviour ExAdServer.TypedSet.BehaviorKeysProcessor

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

  def findInIndex(adRequest, {indexName, _}, indexes, accumulator) do
    {adsStore, _} = getStore("adsStore", indexes)

    # here the id is to copy matching id in the new accumulator, not delete from
    # the original
    Enum.reduce(accumulator, MapSet.new,
                fn(ad_id, acc) ->
                  [{^ad_id, ad_conf}] = ETS.lookup(adsStore, ad_id)
                    conf_values = ad_conf["targeting"][indexName]
                    conf_inclusive = conf_values["inclusive"]
                    conf_data = conf_values["data"]

                    cond do
                      conf_inclusive == true and adRequest[indexName] in conf_data
                              -> MapSet.put(acc, ad_id)
                      conf_inclusive == true and conf_data == ["all"]
                              -> MapSet.put(acc, ad_id)
                      conf_inclusive == false and (adRequest[indexName] in conf_data) == false
                              -> MapSet.put(acc, ad_id)
                      true -> acc
                    end
                end)
  end
end
