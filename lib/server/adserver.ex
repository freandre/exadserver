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
  """
  def filterAd(server) do
    GenServer.call(server, {:filter})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, ETS.new(:adsStore, [:set, :protected])}
  end

  def handle_call({:load, ad}, _from, adsStore) do
    ETS.insert(adsStore, {ad["adid"], ad})
    {:reply, :ok, adsStore}
  end

  def handle_call({:getAd, adId}, _from, adsStore) do
    case ETS.lookup(adsStore, adId) do
      [{^adId, ad}] -> {:reply, ad, adsStore}
      [] -> {:reply, :notfound, adsStore}
    end
  end

  def handle_call({:filter}, _from, adsStore) do
    #to stream latter + take n first
    value = ETS.select(adsStore, [
        {
          :"$1",
          [],
          [:"$_"]
        }
      ]
    )

    case value do
      [_|_] -> {:reply, Enum.map(value, &(elem(&1, 1))), adsStore}
      [] -> {:reply, value, adsStore}
    end
  end
end
