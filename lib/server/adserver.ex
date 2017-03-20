defmodule Server.AdServer do
  @compile {:parse_transform, :ms_transform}

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
    answer = adRequest
             |> Enum.filter(fn({ixName, _}) -> !Map.has_key?(indexes, ixName) end)
             |> Enum.map(fn({ixName, _}) -> ixName end)
             |> Enum.reduce("", fn(ixName, acc) -> acc <> ixName end)

    case answer do
      "" -> :ok
      _ -> "The following target attributes are not available: " <> answer
    end
  end

  defp filterRequest(adRequest, indexes, adsStore) do
    Enum.reduce(adRequest,
         MapSet.new(ETS.select(adsStore, ETS.fun2ms(fn({adId, _}) -> adId end))),
         fn({indexName, indexValue}, acc) ->
           case MapSet.size(acc) do
             0 -> acc
             _ -> findInIndex(indexes[indexName], indexValue)
                  |> MapSet.intersection(acc)
           end
         end)
  end

  defp findInIndex(etsStore, value) do
    dumpETS(etsStore)
    ret = MapSet.new(ETS.select(etsStore,
                 ETS.fun2ms(fn({{inclusive, storedValue}, id})
                              when
                              (inclusive == true and
                                    (storedValue == "all" or storedValue == value))
                                or (inclusive == false and storedValue != value)
                              ->
                           id
                 end)))
    IO.puts(inspect(ret))
    ret
  end

  defp dumpETS(etsStore) do
    IO.puts("Store: " <> Atom.to_string(ETS.info(etsStore)[:name]))
    ETS.match(etsStore, :"$1")
    |> Enum.each(&IO.puts(inspect(&1)))
  end
end
