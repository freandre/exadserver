defmodule ExAdServer.Indexes.InfiniteKeyProcessor do
  @moduledoc """
  Infinite key processor implementation.
  """

  @behaviour ExAdServer.Indexes.BehaviorKeysProcessor

  require Logger
  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  ## Behaviour Callbacks

  def generateMetadata(targeterMetada) do

    ret = targeterMetada
    |> Enum.filter_map(fn ({_, v}) -> v["type"] == "infinite" end,
                       fn ({k, v}) ->
                         createBagStore(getIxAtom(k))
                         {k, ExAdServer.Indexes.InfiniteKeyProcessor, v}
                       end)
    Logger.debug fn -> "[InfiniteKeyProcessor] - Exiting generateMetadata returning:\n#{inspect(ret)}" end
    ret
  end

  def generateAndStoreIndex({ad_conf, _}, {indexName, _}) do
    # We store only inclusive value to speed up search
    conf_inclusive = ad_conf["targeting"][indexName]["inclusive"]
    conf_data = ad_conf["targeting"][indexName]["data"]
    if conf_inclusive == true do
      Enum.each(conf_data, &(ETS.insert(getIxAtom(indexName), {&1, ad_conf["adid"]})))
    end
  end

  def findInIndex(ad, name, acc), do: findInIndexOpt(ad, name, acc)

  def findInIndexOpt(adRequest, {indexName, _}, accumulator) do
    ad_ids = ETS.lookup(getIxAtom(indexName), adRequest[indexName])
    |> Enum.reduce(MapSet.new, fn({_, ad_id}, acc) -> MapSet.put(acc, ad_id) end)

    accumulator = MapSet.intersection(accumulator, ad_ids)

IO.puts(inspect(accumulator))

Enum.reduce(accumulator, accumulator,
                fn(ad_id, acc) ->
                  [{^ad_id, ad_conf}] = ETS.lookup(:ads_store, ad_id)
                    conf_inclusive = ad_conf["targeting"][indexName]["inclusive"]
                    conf_data = ad_conf["targeting"][indexName]["data"]

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

  def findInIndexOrg(adRequest, {indexName, _}, accumulator) do
    Enum.reduce(accumulator, accumulator,
                fn(ad_id, acc) ->
                  [{^ad_id, ad_conf}] = ETS.lookup(:ads_store, ad_id)
                    conf_inclusive = ad_conf["targeting"][indexName]["inclusive"]
                    conf_data = ad_conf["targeting"][indexName]["data"]

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

  def cleanup(indexName, _) do
    deleteStore(getIxAtom(indexName))
  end
end
