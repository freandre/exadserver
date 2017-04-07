defmodule ExAdServer.TypedSet.GeoKeyProcessor do
  @moduledoc """
  Geo key processor implementation.
  """

  @behaviour ExAdServer.TypedSet.BehaviorKeysProcessor

  require Logger
  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  ## Sorted array giving for a bit precision the approximation radius in meters of geohash
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
                  {30, 1_223.0056},
                  {28, 2_446.0112},
                  {26, 4_892.0224},
                  {24, 9_784.0449},
                  {22, 19_568.0898},
                  {20, 39_136.1797},
                  {18, 78_272.35938},
                  {16, 156_544.7188},
                  {14, 313_089.4375},
                  {12, 626_178.875},
                  {10, 1_252_357.75},
                  {8, 2_504_715.5},
                  {6, 5_009_431},
                  {4, 10_018_863}]

  ## Behaviour Callbacks

  def generateMetadata(targeterMetada) do
    ret = targeterMetada
    |> Enum.filter_map(fn ({_, v}) -> v["type"] == "geo" end,
                       fn ({k, v}) -> {k, ExAdServer.TypedSet.GeoKeyProcessor, v} end)
    Logger.debug fn -> "[GeoKeyProcessor] - Exiting generateMetadata returning:\n
                        #{inspect(ret)}" end
    ret
  end

  def generateAndStoreIndex({adConf, _}, {indexName, _}, indexes) do
    {store, indexes} = getStore(indexName, indexes)

    geo_targets = getGeoTargets(adConf["targeting"][indexName]["data"])
    inclusive = adConf["targeting"][indexName]["inclusive"]
    Logger.debug "[GeoKeyProcessor] - generateAndStoreIndex processing:"
    Logger.debug fn -> "inclusive: #{inspect(inclusive)}" end
    Logger.debug fn -> "#{inspect(geo_targets)}" end

    ret = geo_targets
    |> Enum.map(fn(geo_target) ->
                  Geohash.encode(geo_target["latitude"], geo_target["longitude"], geo_target["precision"])
                end)
    |> Enum.flat_map(fn(hash) ->
                       [hash | hash
                               |> Geohash.neighbors
                               |> Enum.map(fn ({_, key}) -> key end)]
                     end)
    |> MapSet.new

    Logger.debug fn -> "> :#{inspect(ret)}" end

    ETS.insert(store, {adConf["adid"], {inclusive, ret}})

    indexes
  end

  def findInIndex(adRequest, {indexName, _}, indexes, accumulator) do
    {store, _} = getStore(indexName, indexes)

    hashes = adRequest[indexName]
             |> getGeoHashes
             |> MapSet.new

    Logger.debug fn -> "[GeoKeyProcessor] - findInIndex hash: #{inspect(hashes)}" end

    Enum.reduce(accumulator, accumulator,
                fn(ad_id, acc) ->
                  [{^ad_id, {inclusive, conf_hashes}}] = ETS.lookup(store, ad_id)

                    cond do
                      inclusive == false and
                          MapSet.size(MapSet.intersection(conf_hashes, hashes)) != 0
                              -> MapSet.delete(acc, ad_id)
                      inclusive == true and
                          MapSet.size(MapSet.intersection(conf_hashes, hashes)) == 0
                              -> MapSet.delete(acc, ad_id)
                      true -> acc
                    end
                end)
  end

  ## Private functions

  ## Create a list of geotargets to deal with
  defp getGeoTargets(geotargets), do: Enum.map(geotargets, &getGeoTarget/1)

  ## Create a map with latitude, longitude, precision
  defp getGeoTarget(geotarget) when geotarget == "all" do
    %{"latitude" => 0,
    "longitude" => 0,
    "precision" => 1}
  end
  defp getGeoTarget(geotarget) do
    %{"latitude" => geotarget["latitude"],
    "longitude" => geotarget["longitude"],
    "precision" => getResolution(geotarget["radius"])}
  end

  ## Find the immediate upper resolution based on radius
  ## if no radius is given, the whole planet is the target
  defp getResolution(nil), do: 1 # return the biggest value
  defp getResolution(radius), do: parseResolutionList(@bitresolution, radius)

  ## Geohash library approximate the nbits by doing precision * 5
  defp computeResolution(nbBits), do: round(nbBits / 5)

  ## Recursively parse precision array
  defp parseResolutionList([val | remaining], radius) do
    if elem(val, 1) > radius do
      computeResolution(elem(val, 0))
    else
      parseResolutionList(remaining, radius)
    end
  end

  ## Get a list oh geohash to look for
  defp getGeoHashes(nil), do: [Geohash.encode(0, 0, 1)]
  defp getGeoHashes(geo) do
    Enum.map(@bitresolution,
            fn({nbBits, _}) ->
              Geohash.encode(geo["latitude"], geo["longitude"], computeResolution(nbBits))
            end)
  end
end
