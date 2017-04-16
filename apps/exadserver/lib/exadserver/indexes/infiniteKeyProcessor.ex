defmodule ExAdServer.Indexes.InfiniteKeyProcessor do
  @moduledoc """
  Infinite key processor implementation.
  """
  @compile {:parse_transform, :ms_transform}

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
                         createBagStore(getIxAtom(k <> "Full"))
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
    Enum.each(conf_data, &(ETS.insert(getIxAtom(indexName <> "Full"), {{conf_inclusive, &1}, ad_conf["adid"]})))
  end

  def findInIndex(ad, name, acc), do: findInIndexETSLookup(ad, name, acc)

  def findInIndexETSIncludeExclude(adRequest, {index_name, _}, accumulator) do
    Logger.debug fn -> "[InfiniteKeyProcessor] - findInIndex request #{index_name}:\n#{inspect(adRequest)}\n#{inspect(accumulator)}" end
    value = adRequest[index_name]

    # Get the inclusive value
    ret = ETS.lookup(getIxAtom(index_name <> "Full"), {true, value})
    |> Enum.reduce(MapSet.new, fn({_, ad_id}, acc) -> MapSet.put(acc, ad_id) end)

    Logger.debug fn -> "> inclusion value #{index_name} => #{inspect(ret)}" end

    ret = ETS.lookup(getIxAtom(index_name <> "Full"), {true, "all"})
    |> Enum.reduce(ret, fn({_, ad_id}, acc) -> MapSet.put(acc, ad_id) end)

    Logger.debug fn -> "> inclusion all #{index_name} => #{inspect(ret)}" end

    ret = ETS.select(getIxAtom(index_name <> "Full"), ETS.fun2ms(fn({{inclusive, storedValue}, id})
                            when
                              (inclusive == false and storedValue != value
                                and storedValue != "all")
                            ->
                              id
                            end))
    |> Enum.reduce(ret, fn(ad_id, acc) -> MapSet.put(acc, ad_id) end)

    Logger.debug fn -> "> inclusion others #{index_name} => #{inspect(ret)}" end

    ret = MapSet.intersection(accumulator, ret)

    Logger.debug fn -> "> intersection #{index_name} => #{inspect(ret)}" end

    # Exclude
    ret = ETS.lookup(getIxAtom(index_name <> "Full"), {false, value})
    |> Enum.reduce(ret, fn({_, ad_id}, acc) -> MapSet.delete(acc, ad_id) end)

    Logger.debug fn -> "> exclusion #{index_name} => #{inspect(ret)}" end

    ret
  end

  def findInIndexETSMapSet(adRequest, {index_name, _}, accumulator) do
    Logger.debug fn -> "[InfiniteKeyProcessor] - findInIndex request #{index_name}:\n#{inspect(adRequest)}\n#{inspect(accumulator)}" end
    value = adRequest[index_name]

    # Get the inclusive value
    ad_ids = ETS.lookup(getIxAtom(index_name), value)
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
                      (conf_inclusive == false and ((value in conf_data) == false))
                        -> MapSet.put(acc, ad_id)
                      true -> acc
                    end
                end)

    Logger.debug fn -> "> exclusion #{index_name} => #{inspect(exclude)}" end

    MapSet.union(inter, exclude)
  end

  def findInIndexETSLookup(adRequest, {indexName, _}, accumulator) do
    Logger.debug fn -> "[InfiniteKeyProcessor] - findInIndex request #{indexName}:\n#{inspect(adRequest)}\n#{inspect(accumulator)}" end
    value = adRequest[indexName]

    Enum.reduce(accumulator, accumulator,
                fn(ad_id, acc) ->
                  [{^ad_id, ad_conf}] = ETS.lookup(:ads_store, ad_id)
                    conf_inclusive = ad_conf["targeting"][indexName]["inclusive"]
                    conf_data = ad_conf["targeting"][indexName]["data"]

                    cond do
                      conf_inclusive == false and value in conf_data
                              -> MapSet.delete(acc, ad_id)
                      conf_inclusive == false and conf_data == ["all"]
                              -> MapSet.delete(acc, ad_id)
                      conf_inclusive == true and ((value in conf_data) == false)
                                             and conf_data != ["all"]
                              -> MapSet.delete(acc, ad_id)
                      true -> acc
                    end
                end)
  end

  def cleanup(indexName, _) do
    deleteStore(getIxAtom(indexName))
    deleteStore(getIxAtom(indexName <> "Full"))
  end
end
