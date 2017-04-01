defmodule ExAdServer.TypedSet.AdServer do
  @moduledoc """
  Implementation of an ad server engine based on sequential set intersection.
  Finite values are dernormalized to find adid
  """

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
    ads_store = ETS.new(:adsStore, [])
    ix_ads_store = ETS.new(:ixAdsStore, [])
    indexes = %{}
    metadata = getMetadata(targetMetadata)
    {:ok, [adsStore: {ads_store, ix_ads_store, 0}, indexes: indexes, targetMetadata: metadata]}
  end

  ## handle_call callback for :load action, iterate on targeting keys creating
  ## an index for each
  def handle_call({:load, adConf}, _from, state) do
    {ads_store, ix_ads_store, num_ads} = state[:adsStore]
    ETS.insert(ads_store, {adConf["adid"],  adConf})
    ETS.insert(ix_ads_store, {num_ads, adConf["adid"]})
    state = Keyword.put(state, :adsStore, {ads_store, ix_ads_store, num_ads + 1})
    state = Keyword.put(state, :indexes,
              Enum.reduce(state[:targetMetadata], state[:indexes],
              fn({indexName, indexProcessor, indexMetaData}, indexes) ->
                indexProcessor.generateAndStoreIndex({adConf, num_ads}, {indexName, indexMetaData}, indexes)
              end))
    {:reply, :ok, state}
  end

  ## handle_call callback for :getAd, perform a lookup on main  ad table
  def handle_call({:getAd, adId}, _from, state) do
    case ETS.lookup(elem(state[:adsStore], 0), adId) do
      [] -> {:reply, :notfound, state}
      [{^adId, ad}] -> {:reply, ad, state}
    end
  end

  ## handle_call callback for :filter, performs some targeting based on a
  ## targeting request
  def handle_call({:filter, adRequest}, _from, state) do
    {_, ix_ads_store, _} = state[:adsStore]
    indexes = state[:indexes]
    target_metadata = state[:targetMetadata]

    with :ok <- validateRequest(adRequest, indexes) do
      ret = Enum.reduce_while(target_metadata, :first,
                      fn({indexName, indexProcessor, indexMetaData}, acc) ->
                        set = indexProcessor.findInIndex(adRequest, ix_ads_store,
                                          {indexName, indexMetaData}, indexes)
                        cond do
                          :first == acc and MapSet.size(set) == 0 -> {:halt, set}
                          :first == acc and MapSet.size(set) != 0 -> {:cont, set}
                          :first != acc and MapSet.size(set) == 0 -> {:halt, set}
                          :first != acc and MapSet.size(set) != 0 -> {:cont, MapSet.intersection(set, acc)}
                        end
                      end)
      {:reply, ret, state}
    else
      reason -> {:reply, {:badArgument, reason}, state}
    end
  end

  ## Private functions

  ## Prepare a list of processor to create keys. finite set are put first to filter
  ## most of the request, followed by infinite and finally the most computer
  ## intensive geolocation. Finite set are  aggregated to handle bitwise
  ## filtering
  defp getMetadata(targetMetadata) do
    {finite, infinite, geo} = Enum.reduce(targetMetadata, {[], [], []},
                fn({k, v}, {finite, infinite, geo}) ->
                  case v["type"] do
                    "finite" -> {[{k, ExAdServer.TypedSet.FiniteKeyProcessor, v} | finite], infinite, geo}
                    "infinite" -> {finite, [{k, ExAdServer.TypedSet.InfiniteKeyProcessor, v} | infinite], geo}
                    "geo" -> {finite, infinite, [{k, ExAdServer.TypedSet.GeoKeyProcessor, v} | geo]}
                  end
                end)

    finite_map = Enum.reduce(finite, %{},
                fn ({k_to_add,_, v_to_add}, acc) ->
                  Map.put_new(acc, k_to_add, v_to_add)
                end)
    [{"finite", ExAdServer.TypedSet.FiniteKeyProcessor, finite_map} | infinite] ++ geo
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
end
