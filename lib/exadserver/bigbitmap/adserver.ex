defmodule ExAdServer.BigBitmap.AdServer do
  @moduledoc """
  Implementation of an ad server engine based on sequential set intersection.
  Finite values are encoded to bitmap integer for performance in ets store retrieval
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
    ads_store = ETS.new(:adsStore, [:set, :protected])
    indexes = %{"adsStore" => ads_store}
    metadata = getMetadata(targetMetadata)
    {:ok, [indexes: indexes, targetMetadata: metadata]}
  end

  ## handle_call callback for :load action, iterate on targeting keys creating
  ## an index for each
  def handle_call({:load, adConf}, _from, state) do
    ETS.insert(state[:indexes]["adsStore"], {adConf["adid"], adConf})
    state = Keyword.put(state, :indexes,
              Enum.reduce(state[:targetMetadata], state[:indexes],
              fn({indexName, indexProcessor, indexMetaData}, indexes) ->
                indexProcessor.generateAndStoreIndex(adConf, {indexName, indexMetaData}, indexes)
              end))
    {:reply, :ok, state}
  end

  ## handle_call callback for :getAd, perform a lookup on main  ad table
  def handle_call({:getAd, adId}, _from, state) do
    case ETS.lookup(state[:indexes]["adsStore"], adId) do
      [] -> {:reply, :notfound, state}
      [{^adId, ad}] -> {:reply, ad, state}
    end
  end

  ## handle_call callback for :filter, performs some targeting based on a
  ## targeting request
  def handle_call({:filter, adRequest}, _from, state) do
    indexes = state[:indexes]
    target_metadata = state[:targetMetadata]

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
  end

  ## Private functions

  ## Prepare a list of processor to create keys. finite set are put first to filter
  ## most of the request, followed by inifintie and finally the most computer
  ## intensive geolocation. Finite set are  aggregated to generate only one key
  defp getMetadata(targetMetadata) do
    {finite, infinite, geo} = Enum.reduce(targetMetadata, {[], [], []},
                fn({k, v}, {finite, infinite, geo}) ->
                  case v["type"] do
                    "finite" -> {[{k, ExAdServer.BigBitmap.FiniteKeyProcessor, v} | finite], infinite, geo}
                    "infinite" -> {finite, [{k, ExAdServer.BigBitmap.InfiniteKeyProcessor, v} | infinite], geo}
                    "geo" -> {finite, infinite, [{k, ExAdServer.BigBitmap.GeoKeyProcessor, v} | geo]}
                  end
                end)

    finite_list = Enum.map(finite,
                fn ({k_to_add,_, v_to_add}) ->
                  {k_to_add, v_to_add}
                end)
    [{"finite", ExAdServer.BigBitmap.FiniteKeyProcessor, finite_list} | infinite] ++ geo
  end
end
