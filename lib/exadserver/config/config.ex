defmodule ExAdServer.Config.ConfigServer do
  use GenServer

  ## Client API

  @doc """
  Starts the server.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end


  ## Server Callbacks

  def init(:ok) do
  end

  def handle_call({:load, ad}, _from, state) do
  end

  def handle_call({:getAd, adId}, _from, state) do
  end

  def handle_call({:filter, adRequest}, _from, state) do
  end

  ## Private functions
