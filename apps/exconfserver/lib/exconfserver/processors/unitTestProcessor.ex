defmodule  ExConfServer.Processors.UnitTestProcessor do
  @moduledoc """
  Mock configuration implementation. It generates a number of config based on
  metadata.
  """

  @behaviour ExConfServer.Processors.BehaviorConfigProcessor

  ## Behaviour Callbacks

  def init({path, numberOfAds}) do
    targeting_data = path
                     |> File.read!()
                     |> Poison.decode!

    targets_metadata = Enum.reduce(targeting_data, %{},
                                  fn({targetName, values}, acc) ->
                                    Map.put(acc, targetName, prepareMetadata(values))
                                  end)

    # generate ads
    ads_map = generateAdsConf(numberOfAds, targeting_data, targets_metadata)


    [adsMap: ads_map, targetsMetadata: targets_metadata]
  end

  def getAd(keywordArgs, adId) do
    ads_map = keywordArgs[:adsMap]
    case adId do
      :all -> Enum.map(ads_map, fn({_, ad}) -> ad end)
      _ -> ads_map[adId]
    end
  end

  def getMetadata(keywordArgs, targetName) do
    target_metadata = keywordArgs[:targetsMetadata]
    case targetName do
      :all -> Map.to_list(target_metadata)
      _ -> target_metadata[targetName]
    end
  end

  ## Private functions

  ## Generate random ad configuration
  defp generateAdsConf(nb, targetingData, targetsMetadata) do
    if nb > 0 do
      1..nb
      |> Enum.to_list
      |> Enum.reduce(%{},
                     fn(_, acc) ->
                       targeting_obj = generateTargeting(targetingData, targetsMetadata)
                       Map.put(acc, targeting_obj["adid"], targeting_obj)
                     end)
    else
      %{}
    end
  end

  ## Generate a targeting object for testing purpose
  defp generateTargeting(targetsData, targetsMetadata) do
    #generate a liste of target
    targeting = Enum.reduce(targetsData, %{},
                fn({target_name, _} = targetData, acc) ->
                  {target_name, target_value} = generateTarget(targetData, targetsMetadata[target_name])
                  Map.put(acc, target_name, target_value)
                end)
    %{"adid" => UUID.uuid1(), "targeting" => targeting}
  end

  ## Generate a target object for testing purpose
  defp generateTarget({targetName, targetValues}, targetMetadata) do
    data_list = targetValues["data"]
    {targetName, %{"inclusive" => :rand.uniform(2) > 1, "data" => generateValueList(data_list, targetMetadata)}}
  end

  # Generate a list of filtering values
  defp generateValueList(dataList, %{"type" => "geo"}), do: generateValueListNb(dataList, 1)
  defp generateValueList(dataList, _), do: generateValueListNb(dataList, :rand.uniform(length(dataList)))
  defp generateValueListNb(dataList, numberOfValues) do
    if :rand.uniform(100) > 75 do
      ["all"]
    else
      recGenerateValueList(dataList, numberOfValues, [])
    end
  end

  # Recursively pick n values values
  defp recGenerateValueList(dataList, numberOfValues, listOfValue) do
      if length(listOfValue) < numberOfValues do
        recGenerateValueList(dataList, numberOfValues, listOfValue ++
                      [Enum.at(dataList, :rand.uniform(length(dataList)) - 1)])
      else
        listOfValue
      end
  end

  # Prepare metadata block containing type, if our type is finite, all distinct
  # values are also returned
  defp prepareMetadata(values) do
    case values["type"] do
      "finite" -> %{"type" => values["type"], "distinctvalues" => Enum.sort(values["data"])}
      _ -> %{"type" => values["type"]}
    end
  end
end
