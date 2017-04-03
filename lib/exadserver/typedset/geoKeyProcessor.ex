defmodule ExAdServer.TypedSet.GeoKeyProcessor do
  @moduledoc """
  Geo key processor implementation.
  """

  @behaviour ExAdServer.TypedSet.BehaviorKeysProcessor

  require Logger
  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  ## Sorted array giving for a bit precision the approximation radius of geohash
  @bitresolution [{52, 0.5971},
                  {50, 1.1943},
                  {48, 2.3889},
                  {46, 4.7774},
                  {44, 9.5547},
                  {42, 19.1095},
                  {40, 38.2189},
                  {38, 76.4378},
                  {36, 152.8757},
                  {34, 305.751},
                  {32, 611.5028},
                  {30, 1223.0056},
                  {28, 2446.0112},
                  {26, 4892.0224 },
                  {24, 9784.0449},
                  {22, 19568.0898},
                  {20, 39136.1797},
                  {18, 78272.35938},
                  {16, 156544.7188},
                  {14, 313089.4375},
                  {12, 626178.875},
                  {10, 1252357.75},
                  {8, 2504715.5},
                  {6, 5009431},
                  {4, 10018863}]

  ## Behaviour Callbacks

  def generateMetadata(targeterMetada) do
    ret = targeterMetada
    |> Enum.filter_map(fn ({_, v}) -> v["type"] == "geo" end,
                       fn ({k, v}) -> {k, ExAdServer.TypedSet.GeoKeyProcessor, v} end)
    Logger.debug fn -> "[GeoKeyProcessor] - Exiting generateMetadata returning:\n#{inspect(ret)}" end
    ret
  end

  def generateAndStoreIndex({adConf, _}, {indexName, _}, indexes) do
    {store, indexes} = getBagStore(indexName, indexes)

    # Assume that geotargeting is only inclusive
    geo_target = getGeoTarget(adConf["targeting"][indexName]["geo"])

    Geohash.encode(geo_target["latitude"], geo_target["longitude"], geo_target["precision"])
    |> Geohash.neighbors
    |> Enum.map(fn ({_, key}) -> key end)
    |> Enum.each(&(ETS.insert(store, {&1, adConf["adid"]})))

    indexes
  end

  def findInIndex(adRequest, {indexName, _}, indexes, accumulator) do
    {store, _} = getBagStore(indexName, indexes)

    getGeoHash(adRequest[indexName])
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

  ## Create a map with latitude, longitude, precision
  defp getGeoTarget(geotarget) do
    if geotarget == nil or geotarget == "all" do
      %{"latitude" => 0,
      "longitude" => 0,
      "precision" => 1}
    else
      %{"latitude" => geotarget["latitude"],
      "longitude" => geotarget["longitude"],
      "precision" => getResolution(geotarget["radius"])}
    end
  end

  ## Find the immediate upper resolution based on radius
  ## if no radius is given, the whole planet is the target
  defp getResolution(radius) do
      if radius == nil do
        parseResolutionList([], radius)
      else
        parseResolutionList(@bitresolution, radius)
      end
  end

  ## Recursively parse precision array
  defp parseResolutionList(bitresolution, radius) do
    case bitresolution do
       [] -> 1 # return the biggest value
       _ ->  [val | remaining] = bitresolution
             if elem(val, 1) > radius do
               round(elem(val, 0) / 5) # geohash library approximate the nbits by doing precision * 5
             else
               parseResolutionList(remaining, radius)
             end
    end
  end

  ## Get a list oh geohash to look for
  def getGeoHash(geo) do
    if geo == nil do
      [Geohash.encode(0, 0, 1)]
    else
      Enum.map(@bitresolution,
              fn({nbBits, _}) ->
                Geohash.encode(geo["latitude"], geo["longitude"], round(nbBits / 5))
              end)
    end
  end
end
