defmodule  ExAdServer.Config.UnitTestProcessor do
  @behaviour ExAdServer.Config.BehaviorConfigProcessor

  ## Behaviour Callbacks

  def init({path, numberOfAds}) do
    targetingData = File.read!(path)
                    |> Poison.decode!
    # generate ads
    adsMap = 1..numberOfAds
            |> Enum.to_list
            |> Enum.reduce(%{},
                           fn(_, acc) ->
                             targetingObj = generateTargeting(targetingData)
                             Map.put(acc, targetingObj["adid"], targetingObj)
                           end)
    targetMetadata = Enum.reduce(targetingData, %{},
                                 fn({targetName, values}, acc) ->
                                   Map.put(acc, targetName, prepareMetadata(values))
                                 end)

    [adsMap: adsMap, targetMetadata: targetMetadata]
  end

  def getAd(keywordArgs, adId) do
    adsMap = keywordArgs[:adsMap]
    case adId do
      :all -> Enum.map(adsMap, fn({_, ad}) -> ad end)
      _ -> adsMap[adId]
    end
  end

  def getMetadata(keywordArgs, targetName) do
    targetMetadata = keywordArgs[:targetMetadata]
    case targetName do
      :all -> Map.to_list(targetMetadata)
      _ -> targetMetadata[targetName]
    end
  end

  ## Private functions

  ## Generate a targeting object for testing purpose
  defp generateTargeting(targetsData) do
    #generate a liste of target
    targeting = Enum.reduce(targetsData, %{},
                fn(targetData, acc) ->
                  {targetName, targetValue} = generateTarget(targetData)
                  Map.put(acc, targetName, targetValue)
                end)
    %{"adid" => UUID.uuid1(), "targeting" => targeting}
  end

  ## Generate a target object for testing purpose
  defp generateTarget({targetName, targetValues}) do
    dataList = targetValues["data"]
    {targetName, %{"inclusive" => :rand.uniform(2) > 1, "data" => generateValueList(dataList)}}
  end

  # Generate a list of filtering values
  defp generateValueList(dataList) do
    numberOfValues = :rand.uniform(length(dataList))
    recGenerateValueList(dataList, numberOfValues, [])
  end

  # Recursivelyu pick n values values
  defp recGenerateValueList(dataList, numberOfValues, listOfValue) do
    cond do
      length(listOfValue) < numberOfValues ->
        recGenerateValueList(dataList, numberOfValues, listOfValue ++
                      [Enum.at(dataList, :rand.uniform(length(dataList)) - 1)])
      true -> listOfValue
    end
  end

  # Prepare metadata block cntaining type, if our type is finite, all distinct
  # values are also returned
  defp prepareMetadata(values) do
    case values["type"] do
      "finite" -> %{"type" => values["type"], "distinctvalues" => Enum.sort(values["data"])}
      _ -> %{"type" => values["type"]}
    end
  end
end
