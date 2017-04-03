defmodule ExAdServer.TypedSet.InfiniteKeyProcessor do
  @moduledoc """
  Infinite key processor implementation.
  """

  @behaviour ExAdServer.TypedSet.BehaviorKeysProcessor

  require Logger
  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  ## Behaviour Callbacks

  def generateMetadata(targeterMetada) do
    ret = targeterMetada
    |> Enum.filter_map(fn ({_, v}) -> v["type"] == "infinite" end,
                       fn ({k, v}) -> {k, ExAdServer.TypedSet.InfiniteKeyProcessor, v} end)
    Logger.debug fn -> "[InfiniteKeyProcessor] - Exiting generateMetadata returning:\n#{inspect(ret)}" end
    ret
  end

  def generateAndStoreIndex(_, {indexName, _}, indexes) do
    Map.put(indexes, indexName, nil)
  end

  def findInIndex(adRequest, {indexName, _}, indexes, accumulator) do
    {adsStore, _} = getBagStore("adsStore", indexes)

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
