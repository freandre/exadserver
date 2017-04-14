defmodule ExJSONRPCClient do
  @moduledoc """
  Simple communication module to hit the TCP API
  """

  alias JSONRPC2.Clients.TCP

  @doc """
  Starts the server.
  """
  def start(host, port) do
    :ok = TCP.start(host, port, __MODULE__)
  end

  @doc """
  Hello call to rpc server
  """
  def hello(name) do
    {:ok, ret} = TCP.call(__MODULE__, "hello", [name])
    IO.puts(ret)
  end

  @doc """
  Filter an ad generating a request
  """
  def filterAd(adRequest) do
    {:ok, ret} = TCP.call(__MODULE__, "filterAd", adRequest)
    ret
  end
end
