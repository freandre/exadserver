defmodule ExAdServer do
  @moduledoc """
  Implementation of an ad server engine based on sequential set intersection.
  Finite values are dernormalized to find adid
  """
  require Logger
  import ExAdServer.Indexes
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
    createStore(:ads_store)
    createStore(:bit_ix_to_ads_store)
    metadata = getMetadata(targetMetadata)
    {:ok, [maxIndex: 0, targetMetadata: metadata]}
  end

  ## handle_call callback for :load action, iterate on targeting keys creating
  ## an index for each
  def handle_call({:load, adConf}, _from, state) do
    num_ads = state[:maxIndex]

    ETS.insert(:ads_store, {adConf["adid"],  adConf})
    ETS.insert(:bit_ix_to_ads_store, {num_ads, adConf["adid"]})

    state = Keyword.put(state, :maxIndex, num_ads + 1)
    Enum.each(state[:targetMetadata],
              fn({indexName, indexProcessor, indexMetaData}) ->
                indexProcessor.generateAndStoreIndex({adConf, num_ads}, {indexName, indexMetaData})
              end)
    {:reply, :ok, state}
  end

  ## handle_call callback for :getAd, perform a lookup on main  ad table
  def handle_call({:getAd, adId}, _from, state) do
    case ETS.lookup(:ads_store, adId) do
      [] -> {:reply, :notfound, state}
      [{^adId, ad}] -> {:reply, ad, state}
    end
  end

  ## handle_call callback for :filter, performs some targeting based on a
  ## targeting request
  def handle_call({:filter, adRequest}, _from, state) do
    target_metadata = state[:targetMetadata]
    ret = Enum.reduce_while(target_metadata, :first,
                      fn({indexName, indexProcessor, indexMetaData}, acc) ->
                        set = indexProcessor.findInIndex(adRequest,
                                          {indexName, indexMetaData}, acc)

                        checkMainStopCondition(set, MapSet.size(set))
                      end)
    {:reply, ret, state}
  end

  ## Private functions

  ## Prepare a list of processor to create keys. finite set are put first to filter
  ## most of the request, followed by infinite and finally the most computer
  ## intensive geolocation. Finite set are  aggregated to handle bitwise
  ## filtering
  defp getMetadata(targetMetadata) do
    Logger.debug fn -> "[adserver] - Entering getMetadata:\n #{inspect(targetMetadata)}" end

    ret = FiniteKeyProcessor.generateMetadata(targetMetadata) ++
    InfiniteKeyProcessor.generateMetadata(targetMetadata) ++
    GeoKeyProcessor.generateMetadata(targetMetadata)

    Logger.debug fn -> "[adserver] - Exiting getMetadata:\n#{inspect(ret)}" end

    ret
  end

  ## Shall we stop to loop
  defp checkMainStopCondition(set, setsize) when setsize == 0, do: {:halt, set}
  defp checkMainStopCondition(set, _), do: {:cont, set}
end
