defmodule ExAdServer.TypedSet.GeoKeyProcessor do
  @moduledoc """
  Geo key processor implementation.
  """

  @behaviour ExAdServer.TypedSet.BehaviorKeysProcessor

  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  ## Sorted array giving for a bit precision the approximation radius of geohash
  @bitresolution [{4, 10018863},
                  {6, 5009431},
                  {8, 2504715.5},
                  {10, 1252357.75},
                  {12, 626178.875},
                  {14, 313089.4375},
                  {16, 156544.7188},
                  {18, 78272.35938},
                  {20, 39136.1797},
                  {22, 19568.0898},
                  {24, 9784.0449},
                  {26, 4892.0224},
                  {28, 2446.0112},
                  {30, 1223.0056},
                  {32, 611.5028},
                  {34, 305.751},
                  {36, 152.8757},
                  {38, 76.4378},
                  {40, 38.2189},
                  {42, 19.1095},
                  {44, 9.5547},
                  {46, 4.7774},
                  {48, 2.3889},
                  {50, 1.1943},
                  {52, 0.5971}]

  ## Behaviour Callbacks

  def generateAndStoreIndex({adConf, _}, {indexName, _}, indexes) do
    {store, indexes} = getBagStore(indexName, indexes)

    # Assume that geotargeting is only inclusive
    geo_target = adConf["targeting"][indexName]["data"]
    min_bits = getResolution(geo_target["radius"])

    Geohash.encode(geo_target["latitude"], geo_target["longitude"], min_bits)
    |> Geohash.neighbors
    |> Enum.map(fn ({_, key}) -> key end)
    |> Enum.each(&(ETS.insert(store, {&1, adConf["adid"]})))

    indexes
  end

  def findInIndex(adRequest, {indexName, _}, indexes, accumulator) do
    {adsStore, _} = getStore("indexName", indexes)

    Enum.map(@bitresolution,
            fn({nbBits, _}) ->
              Geohash.encode(lat, lon, round(nbBits / 5))
            end)
    |> Enum.reduce(MapSet.new,
                   fn(key, acc) ->
                     Enum.reduce(ETS.lookup(store, key), acc,
                                 fn({_, adId}, acc) ->
                                   MapSet.put(acc, adId)
                                 end)
                   end)
    |> MapSet.intersection(accumulator)
  end

  ## Private functions

  ## Find the immediate upper resolution based on radius
  defp getResolution(radius) do
      parseResolutionList(@bitresolution, radius)
  end

  ## Recursively parse precision array
  defp parseResolutionList(bitresolution, radius) do
    case bitresolution do
       [] -> round(52 / 5) # return the biggest value
       _ ->  [val | remaining] = bitresolution
             if elem(val, 1) > radius do
               round(elem(val, 0) / 5) # geohash library approximate the nbits by doing precision * 5
             else
               parseResolutionList(remaining, radius)
             end
    end
  end
end
