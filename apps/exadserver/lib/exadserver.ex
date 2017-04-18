defmodule ExAdServer do
  @moduledoc """
  Implementation of an ad server engine based on sequential set intersection.
  Finite values are dernormalized to find adid
  """
  require Logger
  alias ExAdServer.Indexes
  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  use GenServer

  ## Client API

  @doc """
  Starts the server.
  """
  def start_link(name, targetMetadata) do
    Logger.debug "[adserver] - start_link"
    GenServer.start_link(__MODULE__, targetMetadata, [name: name])
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

  @doc """
  Stop the server
  """
  def stop(server) do
    GenServer.stop(server)
  end

  ## Server Callbacks

  ## init callback, we initialize the main store as well as the finite index store,
  ## an empty index registry for not finite values and finally the finite metadata
  ## structure
  def init(targetMetadata) do
    createStore(:ads_store)
    createStore(:bit_ix_to_ads_store)
    metadata = prepareMetadata(targetMetadata)
    {:ok, [maxIndex: 0, targetMetadata: metadata]}
  end

  ## handle_call callback for :load action, iterate on targeting keys creating
  ## an index for each
  def handle_call({:load, adConf}, _from, state) do
    num_ads = state[:maxIndex]
    state = Keyword.put(state, :maxIndex, num_ads + 1)

    Logger.debug fn -> "[adserver] - Storing conf:\n #{inspect(adConf)}" end

    ETS.insert(:ads_store, {adConf["adid"],  adConf})
    ETS.insert(:bit_ix_to_ads_store, {num_ads, adConf["adid"]})

    # Make the index storage parallel
    state[:targetMetadata]
    |> Enum.map(fn({indexName, indexProcessor, indexMetaData}) ->
                  #Task.async(fn ->
                               indexProcessor.generateAndStoreIndex({adConf, num_ads},
                                                                    {indexName, indexMetaData})
                             #end)
                end)
    #|> Enum.map(&(Task.await(&1)))

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
  def handle_call({:filter, adRequest}, from, state) do
    Logger.debug fn -> "[adserver] - Entering filter conf:\n #{inspect(adRequest)}" end
    target_metadata = state[:targetMetadata]

    Task.start(fn ->
                 ret = Enum.reduce_while(target_metadata, :first,
                   fn({indexName, indexProcessor, indexMetaData}, acc) ->
                     set = indexProcessor.findInIndex(adRequest,
                                                      {indexName, indexMetaData}, acc)
                     checkMainStopCondition(set)
                   end)
                 Logger.debug fn -> "[adserver] - Exiting filter conf:\n #{inspect(ret)}" end
                 GenServer.reply(from, ret)
               end)
    {:noreply, state}
  end

  def terminate(_, state) do
    Logger.debug "[adserver] - terminate"
    state[:targetMetadata]
    |> Enum.each(fn({indexName, indexProcessor, indexMetaData}) ->
                  indexProcessor.cleanup(indexName, indexMetaData)
                end)

    deleteStore(:bit_ix_to_ads_store)
    deleteStore(:ads_store)
    :ok
  end

  ## Private functions

  ## Prepare a list of processor to create keys. finite set are put first to filter
  ## most of the request, followed by infinite and finally the most computer
  ## intensive geolocation. Finite set are  aggregated to handle bitwise
  ## filtering
  defp prepareMetadata(targetMetadata) do
    Logger.debug fn -> "[adserver] - Entering prepareMetadata:\n #{inspect(targetMetadata)}" end

    ret = Indexes.FiniteKeyProcessor.generateMetadata(targetMetadata) ++
    Indexes.InfiniteKeyProcessor.generateMetadata(targetMetadata) ++
    Indexes.GeoKeyProcessor.generateMetadata(targetMetadata)

    Logger.debug fn -> "[adserver] - Exiting prepareMetadata:\n#{inspect(ret)}" end

    ret
  end

  ## Shall we stop to loop
  defp checkMainStopCondition([] = list), do: {:halt, list}
  defp checkMainStopCondition(list), do: {:cont, list}
end
