defmodule ExAdServer.Bitmap.AdServer do
  @moduledoc """
  Implementation of an ad server engine based on sequential set intersection.
  Finite values are encoded to bitmap integer for performance
  """

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
    ads_store = ETS.new(:adsStore, [:set, :protected])
    indexes = %{}
    metadata = getMetadata(targetMetadata)
    {:ok, [adsStore: ads_store, indexes: indexes, targetMetadata: metadata]}
  end

  ## handle_call callback for :load action, iterate on targeting keys creating
  ## an index for each
  def handle_call({:load, adConf}, _from, state) do
    ETS.insert(state[:adsStore], {adConf["adid"], adConf})
    state = Keyword.put(state, :indexes,
              Enum.reduce(state[:targetMetadata], state[:indexes],
              fn({indexName, indexProcessor, indexMetaData}, indexes) ->
                indexProcessor.generateAndStoreIndex(adConf, {indexName, indexMetaData}, indexes)
              end
            ))
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
    {finite, infinite, geo} = Enum.reduce(targetMetadata, {[], [], []},
                fn({k, v}, {finite, infinite, geo}) ->
                  case v["type"] do
                    "finite" -> {[{k, ExAdServer.Bitmap.FiniteKeyProcessor, v} | finite], infinite, geo}
                    "infinite" -> {finite, [{k, ExAdServer.Bitmap.InfiniteKeyProcessor, v} | infinite], geo}
                    "geo" -> {finite, infinite, [{k, ExAdServer.Bitmap.GeoKeyProcessor, v} | geo]}
                  end
                end)
    finite ++ infinite ++ geo
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

  end
end
