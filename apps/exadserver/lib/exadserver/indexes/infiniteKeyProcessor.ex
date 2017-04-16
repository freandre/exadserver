defmodule ExAdServer.Indexes.InfiniteKeyProcessor do
  @moduledoc """
  Infinite key processor implementation.
  """
  @compile {:parse_transform, :ms_transform}

  @behaviour ExAdServer.Indexes.BehaviorKeysProcessor

  require Logger
  import ExAdServer.Utils.Storage
  alias ExAdServer.Utils.ListUtils
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

  def findInIndex(adRequest, {indexName, _}, accumulator) do
    Logger.debug fn -> "[InfiniteKeyProcessor] - findInIndex request #{indexName}:\n#{inspect(accumulator)}" end
    value = adRequest[indexName]

    ret = Enum.reduce(accumulator, [],
                fn(ad_id, acc) ->
                  [{^ad_id, ad_conf}] = ETS.lookup(:ads_store, ad_id)
                    conf_inclusive = ad_conf["targeting"][indexName]["inclusive"]
                    conf_data = ad_conf["targeting"][indexName]["data"]

                    cond do
                      conf_inclusive == true and (value in conf_data or conf_data == ["all"])
                              -> [ad_id | acc]
                      conf_inclusive == false and (value in conf_data == false)
                              -> [ad_id | acc]
                      true -> acc
                    end
                end)

    Logger.debug fn -> "[InfiniteKeyProcessor] - findInIndex exit:\n#{inspect(ret)}" end

    ret
  end

  def cleanup(indexName, _) do
    deleteStore(getIxAtom(indexName))
  end
end
