defmodule ExAdServer.TypedSet.AdServer do
  @moduledoc """
  Implementation of an ad server engine based on sequential set intersection.
  Finite values are dernormalized to find adid
  """
  require Logger
  import ExAdServer.Utils.Storage
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
    {_, indexes} = getStore("adsStore")
    {_, indexes} = getStore("bitIxToAdsStore", indexes)
    metadata = getMetadata(targetMetadata)
    {:ok, [maxIndex: 0, indexes: indexes, targetMetadata: metadata]}
  end

  ## handle_call callback for :load action, iterate on targeting keys creating
  ## an index for each
  def handle_call({:load, adConf}, _from, state) do
    num_ads = state[:maxIndex]
    indexes = state[:indexes]

    {ads_store, _} = getStore("adsStore", indexes)
    {ix_ads_store, indexes} = getStore("bitIxToAdsStore", indexes)

    ETS.insert(ads_store, {adConf["adid"],  adConf})
    ETS.insert(ix_ads_store, {num_ads, adConf["adid"]})

    state = Keyword.put(state, :maxIndex, num_ads + 1)
    state = Keyword.put(state, :indexes,
              Enum.reduce(state[:targetMetadata], indexes,
              fn({indexName, indexProcessor, indexMetaData}, indexes) ->
                indexProcessor.generateAndStoreIndex({adConf, num_ads}, {indexName, indexMetaData}, indexes)
              end))
    {:reply, :ok, state}
  end

  ## handle_call callback for :getAd, perform a lookup on main  ad table
  def handle_call({:getAd, adId}, _from, state) do
    {ads_store, _} = getStore("adsStore", state[:indexes])
    case ETS.lookup(ads_store, adId) do
      [] -> {:reply, :notfound, state}
      [{^adId, ad}] -> {:reply, ad, state}
    end
  end

  ## handle_call callback for :filter, performs some targeting based on a
  ## targeting request
  def handle_call({:filter, adRequest}, _from, state) do
    indexes = state[:indexes]
    target_metadata = state[:targetMetadata]

    with :ok <- validateRequest(adRequest, indexes) do
      ret = Enum.reduce_while(target_metadata, :first,
                      fn({indexName, indexProcessor, indexMetaData}, acc) ->
                        set = indexProcessor.findInIndex(adRequest,
                                          {indexName, indexMetaData}, indexes, acc)
                        if MapSet.size(set) == 0 do
                          {:halt, set}
                        else
                          {:cont, set}
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
    Logger.debug fn -> "[adserver] - Entering getMetadata:\n #{inspect(targetMetadata)}" end

    ret = ExAdServer.TypedSet.FiniteKeyProcessor.generateMetadata(targetMetadata) ++
    ExAdServer.TypedSet.InfiniteKeyProcessor.generateMetadata(targetMetadata) ++
    ExAdServer.TypedSet.GeoKeyProcessor.generateMetadata(targetMetadata)

    Logger.debug fn -> "[adserver] - Exiting getMetadata:\n#{inspect(ret)}" end

    ret
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
