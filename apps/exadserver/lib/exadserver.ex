defmodule ExAdServer do
  @moduledoc """
  Implementation of an ad server engine based on sequential set intersection.
  Finite values are dernormalized to find adid
  """
  require Logger
  alias ExAdServer.Indexes
  alias ExAdServer.Finder.FinderServer
  import ExAdServer.Utils.Storage
  alias :ets, as: ETS

  use GenServer

  ## Client API

  @doc """
  Starts the server.
  """
  def start_link(name, targetMetadata, num_workers \\ 100) when num_workers > 0 do
    Logger.debug "[adserver] - start_link"
    GenServer.start_link(__MODULE__, {targetMetadata, num_workers}, [name: name])
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
  def init({metadata, num_workers}) do
    createStore(:ads_store)
    createStore(:bit_ix_to_ads_store)
    target_metadata = prepareMetadata(metadata)
    finder_pool = getPool(target_metadata, num_workers)
    {:ok, [max_index: 0, target_metadata: target_metadata, finder_pool: finder_pool, current: 0]}
  end

  ## handle_call callback for :load action, iterate on targeting keys creating
  ## an index for each
  def handle_call({:load, adConf}, _from, state) do
    num_ads = state[:max_index]
    state = Keyword.put(state, :max_index, num_ads + 1)

    Logger.debug fn -> "[adserver] - Storing conf:\n #{inspect(adConf)}" end

    ETS.insert(:ads_store, {adConf["adid"],  adConf})
    ETS.insert(:bit_ix_to_ads_store, {num_ads, adConf["adid"]})

    state[:target_metadata]
    |> Enum.each(fn({indexName, indexProcessor, indexMetaData}) ->
                               indexProcessor.generateAndStoreIndex({adConf, num_ads},
                                                                    {indexName, indexMetaData})
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
  def handle_call({:filter, adRequest}, from, state) do
    pool = state[:finder_pool]
    {current, state} = Keyword.get_and_update(state, :current, &({&1, rem(&1 + 1, map_size(pool))}))
    FinderServer.filterAd(pool[current], adRequest, from)
    {:noreply, state}
  end

  def terminate(_, state) do
    Logger.debug "[adserver] - terminate"
    state[:target_metadata]
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
  defp prepareMetadata(target_metadata) do
    Logger.debug fn -> "[adserver] - Entering prepareMetadata:\n #{inspect(target_metadata)}" end

    ret = Indexes.FiniteKeyProcessor.generateMetadata(target_metadata) ++
    Indexes.InfiniteKeyProcessor.generateMetadata(target_metadata) ++
    Indexes.GeoKeyProcessor.generateMetadata(target_metadata)

    Logger.debug fn -> "[adserver] - Exiting prepareMetadata:\n#{inspect(ret)}" end

    ret
  end

  ## Prepare a pool of workers
  defp getPool(target_metadata, num_workers) do
    0..(num_workers - 1)
    |> Enum.to_list
    |> Enum.reduce(%{}, &(Map.put(&2, &1, elem(FinderServer.start_link(target_metadata), 1))))
  end
end
