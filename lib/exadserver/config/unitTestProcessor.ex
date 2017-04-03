defmodule  ExAdServer.Config.UnitTestProcessor do
  @moduledoc """
  Mock configuration implementation. It generates a number of config based on
  metadata.
  """

  @behaviour ExAdServer.Config.BehaviorConfigProcessor

  ## Behaviour Callbacks

  def init({path, numberOfAds}) do
    targeting_data = path
                     |> File.read!()
                     |> Poison.decode!
    # generate ads
    ads_map = generateAdsConf(numberOfAds, targeting_data)

    target_metadata = Enum.reduce(targeting_data, %{},
                                 fn({targetName, values}, acc) ->
                                   Map.put(acc, targetName, prepareMetadata(values))
                                 end)

    [adsMap: ads_map, targetMetadata: target_metadata]
  end

  def getAd(keywordArgs, adId) do
    ads_map = keywordArgs[:adsMap]
    case adId do
      :all -> Enum.map(ads_map, fn({_, ad}) -> ad end)
      _ -> ads_map[adId]
    end
  end

  def getMetadata(keywordArgs, targetName) do
    target_metadata = keywordArgs[:targetMetadata]
    case targetName do
      :all -> Map.to_list(target_metadata)
      _ -> target_metadata[targetName]
    end
  end

  ## Private functions

  ## Generate random ad configuration
  defp generateAdsConf(nb, targetingData) do
    if nb > 0 do
      1..nb
      |> Enum.to_list
      |> Enum.reduce(%{},
                     fn(_, acc) ->
                       targeting_obj = generateTargeting(targetingData)
                       Map.put(acc, targeting_obj["adid"], targeting_obj)
                     end)
    else
      %{}
    end
  end

  ## Generate a targeting object for testing purpose
  defp generateTargeting(targetsData) do
    #generate a liste of target
    targeting = Enum.reduce(targetsData, %{},
                fn(targetData, acc) ->
                  {target_name, target_value} = generateTarget(targetData)
                  Map.put(acc, target_name, target_value)
                end)
    %{"adid" => UUID.uuid1(), "targeting" => targeting}
  end

  ## Generate a target object for testing purpose
  defp generateTarget({targetName, targetValues}) do
    data_list = targetValues["data"]
    {targetName, %{"inclusive" => :rand.uniform(2) > 1, "data" => generateValueList(data_list)}}
  end

  # Generate a list of filtering values
  defp generateValueList(dataList) do
    number_of_values = :rand.uniform(length(dataList))
    if :rand.uniform(100) > 75 do
      ["all"]
    else
      recGenerateValueList(dataList, number_of_values, [])
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
