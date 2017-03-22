defmodule  ExAdServer.Config.UnitTestProcessor do
  @behaviour ExAdServer.Config.BehaviorConfigProcessor

  def init({path, numberOfAds}) do
    targetingData = File.read!(path)
                    |> Poison.decode!
    # generate ads
    1..numberOfAds
    |> Enum.to_list
    |> Enum.reduce(%{},
              fn(_, acc) ->
                targetingObj = generateTargeting(targetingData)
                Map.put(acc, targetingObj["adid"], targetingObj)
              end)
  end

  def getAd(mapAds, adId) do
    case adId do
      :all -> Enum.map(mapAds, fn({_, ad}) -> ad end)
      true -> mapAds[adId]
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
        recGenerateValueList(dataList, numberOfValues, listOfValue ++ [Enum.at(dataList, :rand.uniform(length(dataList)) - 1)])
      true -> listOfValue
    end
  end
end
