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

  def findInIndex(adRequest, {indexName, _}, indexes, accumulator) do
    {adsStore, _} = getStore("adsStore", indexes)

    Enum.reduce(accumulator, accumulator,
                fn(ad_id, acc) ->
                  [{^ad_id, ad_conf}] = ETS.lookup(adsStore, ad_id)
                    conf_values = ad_conf["targeting"][indexName]
                    conf_inclusive = conf_values["inclusive"]
                    conf_data = conf_values["data"]

                    cond do
                      conf_inclusive == false and adRequest[indexName] in conf_data
                              -> MapSet.delete(acc, ad_id)
                      conf_inclusive == false and conf_data == ["all"]
                              -> MapSet.delete(acc, ad_id)
                      conf_inclusive == true and ((adRequest[indexName] in conf_data) == false)
                                             and conf_data != ["all"]
                              -> MapSet.delete(acc, ad_id)
                      true -> acc
                    end
                end)
  end
end
