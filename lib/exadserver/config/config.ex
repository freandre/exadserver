defmodule ExAdServer.Config.ConfigServer do
  use GenServer

  ## Client API

  @doc """
  Starts the server.
  """
  def start_link(path \\ :ok) do
    GenServer.start_link(__MODULE__, path, [])
  end


  ## Server Callbacks

  def init(:ok) do
    # will read data from configured datasource
  end

  @doc """
  init based on path, this is mainly used for unit testing
  """
  def init(path) do
    targetingData = File.read!(path)
                    |> Poison.decode!
    # generate 10k ads
    1..1
    |> Enum.to_list
    |> Enum.map(fn(_) -> generateTargeting(targetingData) end)
  end

  def handle_call({:load, ad}, _from, state) do
  end

  def handle_call({:getAd, adId}, _from, state) do
  end

  def handle_call({:filter, adRequest}, _from, state) do
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
  defp generateTarget(targetData) do
    IO.puts(inspect(targetData))
    targetName = Enum.filter(targetData, &(IO.puts(&1)))
                 |> List.first

    dataList = targetData[targetName]["data"]

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
        recGenerateValueList(dataList, numberOfValues, [listOfValue | Enum.at(dataList, :rand.uniform(length(dataList)))])
      true -> listOfValue
    end
  end
end
