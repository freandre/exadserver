defmodule ExJSONRPCClient do
  @moduledoc """
  Simple communication module to hit the TCP API
  """

  alias JSONRPC2.Clients.TCP

  def start(host, port) do
    :ok = TCP.start(host, port, __MODULE__)
  end

  def hello(name) do
    {:ok, ret} = TCP.call(__MODULE__, "hello", [name])
    IO.puts(ret)
  end

  def filterAd() do
    adRequest = ["country", "language", "iab", "hour", "minute"]
    |> Enum.reduce(%{}, &(Map.put(&2, &1, pickValue(ExConfServer.getMetadata(ConfServer, &1)["distinctvalues"]))))

    {:ok, ret} = TCP.call(__MODULE__, "filterAd", adRequest)
    ret
  end

  ## Private functions

  defp pickValue(distinctValues) do
    Enum.at(distinctValues, :rand.uniform(length(distinctValues)) -1 )
  end
end
