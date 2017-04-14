defmodule ExConfServer do
  @moduledoc """
  Configuration micro service hiding the real configuration datasource.
  """

  use GenServer

  ## Client API

  @doc """
  Starts the server.
  """
  def start_link(name, initData) do
    GenServer.start_link(__MODULE__, initData, [name: name])
  end

  @doc """
  Retreive a configuration based on its id or a list of ads if :all is provided
  """
  def getConf(server, adId \\ :all) do
    GenServer.call(server, {:getConf, adId}, :infinity)
  end

  @doc """
  Retreive an ad based on its id or a list of ads if : all is provided
  """
  def getMetadata(server, targetName \\ :all) do
    GenServer.call(server, {:getMetadata, targetName})
  end

  @doc """
  Stop the server
  """
  def stop(server) do
    GenServer.stop(server)
  end

  ## Server Callbacks

  def init(:ok) do
    # TODO will read data from configured datasource
  end

  @doc """
  init based on path, this is mainly used for unit testing
  """
  def init({_path, number_of_ads} = params) when number_of_ads >= 0 do
    processor = ExConfServer.Processors.UnitTestProcessor
    {:ok, [processor: processor, data: processor.init(params)]}
  end

  @doc """
  handle_call delegated to processor set in state
  """
  def handle_call({:getConf, adId}, _from, state) do
    {:reply, state[:processor].getConf(state[:data], adId), state}
  end

  @doc """
  handle_call delegated to processor set in state
  """
  def handle_call({:getMetadata, targetName}, _from, state) do
    {:reply, state[:processor].getMetadata(state[:data], targetName), state}
  end
end
