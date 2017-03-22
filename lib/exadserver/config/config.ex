defmodule ExAdServer.Config.ConfigServer do
  use GenServer

  ## Client API

  @doc """
  Starts the server.
  """
  def start_link(initData) do
    GenServer.start_link(__MODULE__, initData, [])
  end

  def getAd(server, adId \\ :all) do
    GenServer.call(server, {:getAd, adId}, :infinity)
  end

  ## Server Callbacks

  def init(:ok) do
    # TODO will read data from configured datasource
  end

  @doc """
  init based on path, this is mainly used for unit testing
  """
  def init({_path, numberOfAds} = params) when numberOfAds >= 1 do
    processor = ExAdServer.Config.UnitTestProcessor
    {:ok, [processor: processor, data: processor.init(params)]}
  end

  def handle_call({:getAd, adId}, _from, state) do
    {:reply, state[:processor].getAd(state[:data], adId), state}
  end
end
