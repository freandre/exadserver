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
      Logger.debug fn -> "[InfiniteKeyProcessor] - generateAndStoreIndex storing:\n#{inspect(conf_data)}" end
      Enum.each(conf_data, &(ETS.insert(getIxAtom(indexName), {&1, ad_conf["adid"]})))
    end
  end

  def findInIndex(ad, name, acc), do: findInIndexOpt(ad, name, acc)

  def findInIndexOpt(adRequest, {index_name, _}, accumulator) do
    Logger.debug fn -> "[InfiniteKeyProcessor] - findInIndex request #{index_name}:\n#{inspect(adRequest)}\n#{inspect(accumulator)}" end

    # Get the inclusive value
    ad_ids = ETS.lookup(getIxAtom(index_name), adRequest[index_name])
    |> Enum.reduce(MapSet.new, fn({_, ad_id}, acc) -> MapSet.put(acc, ad_id) end)

    #Add the inclusive all
    ad_ids = ETS.lookup(getIxAtom(index_name), "all")
    |> Enum.reduce(ad_ids, fn({_, ad_id}, acc) -> MapSet.put(acc, ad_id) end)

    inter = MapSet.intersection(accumulator, ad_ids)
    Logger.debug fn -> "> inclusion #{index_name} => #{inspect(inter)}" end

    # In the remaining conf id, check the excluding not value pattern
    exclude = Enum.reduce(MapSet.difference(accumulator, ad_ids), MapSet.new,
                fn(ad_id, acc) ->
                  [{^ad_id, ad_conf}] = ETS.lookup(:ads_store, ad_id)
                    conf_inclusive = ad_conf["targeting"][index_name]["inclusive"]
                    conf_data = ad_conf["targeting"][index_name]["data"]

                    cond do
                      (conf_inclusive == false and ((adRequest[index_name] in conf_data) == false))
                        -> MapSet.put(acc, ad_id)
                      true -> acc
                    end
                end)

    Logger.debug fn -> "> exclusion #{index_name} => #{inspect(exclude)}" end

    MapSet.union(inter, exclude)
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
