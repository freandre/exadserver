defmodule ExAdServer.Bitmap.AdServer do
  @compile {:parse_transform, :ms_transform}

  alias :ets, as: ETS

  use GenServer

  ## Client API

  @doc """
  Starts the server.
  """
  def start_link(targetMetadata) do
    GenServer.start_link(__MODULE__, targetMetadata, [])
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
  def getAd(server, adId) do
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

  ## init callback, we initialize the main store as well as the finite index store,
  ## an empty index registry for not finite values and finally the finite metadata
  ## structure
  def init(targetMetadata) do
    adsStore = ETS.new(:adsStore, [:set, :protected])
    indexes = %{}
    metadata = getMetadata(targetMetadata)
    {:ok, [adsStore: adsStore, indexes: indexes, targetMetadata: metadata]}
  end

  ## handle_call callback for :load action, iterate on targeting keys creating
  ## an index for each
  def handle_call({:load, ad}, _from, state) do
    ETS.insert(state[:adsStore], {ad["adid"], ad})
    state = Keyword.put(state, :indexes,
              Enum.reduce(state[:targetMetadata], state[:indexes], &createIndex(ad, &1, &2))
            )
    {:reply, :ok, state}
  end

  ## handle_call callback for :getAd, perform a lookup on main  ad table
  def handle_call({:getAd, adId}, _from, state) do
    case ETS.lookup(state[:adsStore], adId) do
      [] -> {:reply, :notfound, state}
      [{^adId, ad}] -> {:reply, ad, state}
    end
  end

  ## handle_call callback for :filter, performs some targeting based on a
  ## targeting request
  def handle_call({:filter, adRequest}, _from, state) do
    indexes = state[:indexes]

    case validateRequest(adRequest, indexes) do
      :ok -> {:reply, filterRequest(adRequest, indexes, state[:adsStore]), state}
      reason -> {:reply, {:badArgument, reason}, state}
    end
  end

  ## Private functions

  ## Prepare a list of processor to create keys. finite set are put first to filter
  ## most of the request, followed by inifintie and finally the most computer
  ## intensive geolocation
  defp getMetadata(targetMetadata) do
    finite = Enum.filter(targetMetadata, fn({_k, v}) -> v["type"] == "finite" end)
    infinite = Enum.filter_map(targetMetadata,
                               fn({_k, v}) -> v["type"] == "infinite" end,
                               fn({k, v}) -> {k, ExAdServer.Bitmap.InfiniteKeyProcessor, v}
                             end)
    geo = Enum.filter_map(targetMetadata,
                               fn({_k, v}) -> v["type"] == "geo" end,
                               fn({k, v}) -> {k, ExAdServer.Bitmap.GeoKeyProcessor, v} end)
    [{"finite", ExAdServer.Bitmap.FiniteKeyProcessor, finite} | infinite] ++ geo
  end

  ## Return a a store based on index name, instanciate it if it does not exists
  ## thus needing to return also the registry of stores
  defp getStore(indexName, indexes) do
    if !Map.has_key?(indexes, indexName) do
      store = ETS.new(String.to_atom(indexName), [:bag, :protected])
      newIndexes = Map.put(indexes, indexName, store)
      {store, newIndexes}
    else
      {indexes[indexName], indexes}
    end
  end

  ## Create an index based on given index meta data
  defp createIndex(ad, {indexName, indexProcessor, indexMetaData}, indexes) do
    {store, indexes} = getStore(indexName, indexes)
    ETS.insert(store, indexProcessor.getIndexKeyForStorage(ad, indexName, indexMetaData))
    indexes
  end

  ## Validate that a filtering request provides a set of know targets
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

  ## Main filtering function, thanks to an accumulator initalized to all ad values,
  ## we iterate on index removing datas from this accumulator
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

  ## Look values in an index :  we first filter all inclusive data and remove the
  ## exluding ones
  defp findInIndex(etsStore, value) do
    included = MapSet.new(ETS.select(etsStore,
                 ETS.fun2ms(fn({{inclusive, storedValue}, id})
                              when
                              (inclusive == true and
                                    (storedValue == "all" or storedValue == value))
                                or (inclusive == false and storedValue != value)
                              ->
                           id
                 end)))
    excluded = MapSet.new(ETS.select(etsStore,
                 ETS.fun2ms(fn({{inclusive, storedValue}, id})
                              when
                              inclusive == false and storedValue == value
                              ->
                           id
                 end)))
    MapSet.difference(included, excluded)
  end
end
