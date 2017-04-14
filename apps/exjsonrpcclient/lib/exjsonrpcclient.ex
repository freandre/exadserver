defmodule ExJSONRPCClient do
  @moduledoc """
  Simple communication module to hit the TCP API
  """

  alias JSONRPC2.Clients.TCP

  def start(host, port) do
    TCP.start(host, port, __MODULE__)
  end

  def hello(name) do
    TCP.call(__MODULE__, "hello", name)
  end

  def filterAd() do
    adRequest = ["country", "language", "iab", "hour", "minute"]
    |> Enum.reduce(%{}, &(Map.put(&2, &1, pickValue(ExConfServer.getMetadata(ConfServer, &1)["distinctvalues"]))))

    TCP.call(__MODULE__, "filterAd", adRequest)
  end

  ## Private functions

  defp pickValue(distinctValues) do
    Enum.at(distinctValues, :rand.uniform(length(distinctValues)) -1 )
  end
end
