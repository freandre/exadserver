defmodule Server.AdServer do
  alias :ets, as: ETS
  use GenServer

  ## Client API

  @doc """
  Starts the server.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Add or update an ad to the store
  """
  def loadAd(server, %{"adid" => _, "targeting" => _} = ad) do
    GenServer.call(server, {:load, ad})
  end

  @doc """
  Retrieve an ad by its id

  Returns the ad or :notfound
  """
  def getAd(server, adId) when is_integer(adId) do
    GenServer.call(server, {:getAd, adId})
  end

  @doc """
  Main function for filtering ads based on received criteria

  Returns [ads] if something match or []
  In case of targeting argument not supported, :badArgument
  """
  def filterAd(server, adRequest) do
    GenServer.call(server, {:filter, adRequest})
  end

  ## Server Callbacks

  def init(:ok) do
    adsStore = ETS.new(:adsStore, [:set, :protected])
    indexes = %{}
    {:ok, [adsStore: adsStore, indexes: indexes]}
  end

  def handle_call({:load, ad}, _from, state) do
    ETS.insert(state[:adsStore], {ad["adid"], ad})
    state = Keyword.put(state, :indexes,
              Enum.reduce(ad["targeting"], state[:indexes], &createIndex(&1, ad["adid"], &2))
            )
    {:reply, :ok, state}
  end

  def handle_call({:getAd, adId}, _from, state) do
    case ETS.lookup(state[:adsStore], adId) do
      [] -> {:reply, :notfound, state}
      [{^adId, ad}] -> {:reply, ad, state}
    end
  end

  def handle_call({:filter, adRequest}, _from, state) do
    indexes = state[:indexes]

    case validateRequest(adRequest, indexes) do
      :ok -> {:reply, filterRequest(adRequest, indexes, state[:adsStore]), state}
      reason -> {:reply, {:badArgument, reason}, state}
    end
  end

  ## Private functions
  defp getStore(indexName, indexes) do
    if !Map.has_key?(indexes, indexName) do
      store = ETS.new(String.to_atom(indexName), [:bag, :protected])
      newIndexes = Map.put(indexes, indexName, store)
      {store, newIndexes}
    else
      {indexes[indexName], indexes}
    end
  end

  defp createIndex({indexName, indexData}, adId, indexes) do
    {store, indexes} = getStore(indexName, indexes)
    Enum.each(indexData["data"], &ETS.insert(store, {{indexData["inclusive"], &1}, adId}))
    indexes
  end

  defp validateRequest(adRequest, indexes) do
    case Enum.all?(adRequest,
                   fn({indexName, _}) -> Map.has_key?(indexes, indexName) end) do
      true -> :ok
      _ -> []
    end
  end

  defp filterRequest(adRequest, indexes, adsStore) do
    Enum.reduce(adRequest,
         ETS.match(adsStore, {:"$1", :"_"}),
             fn({indexName, indexValue}, acc) ->
                 case acc do
                     [] -> []
                     _ -> findInIndex(indexes[indexName], indexValue) |>
                          MapSet.intersection(acc)
                 end
             end)
  end

  defp findInIndex(etsStore, value) do
    ETS.select(etsStore, fn({{inclusive, storedValue}, id})
          when inclusive == true and (value == "all" or storedValue == value)
          -> id end)
  end
end
