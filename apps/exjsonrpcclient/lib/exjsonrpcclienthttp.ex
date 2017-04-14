defmodule ExJSONRPCClientHTTP do
  @moduledoc """
  Simple communication module to hit the TCP API
  """

  alias JSONRPC2.Clients.HTTP

  @doc """
  Hello call to rpc server
  """
  def hello(url, name) do
    {:ok, ret} = HTTP.call(url, "hello", [name])
    IO.puts(ret)
  end

  @doc """
  Filter an ad generating a request
  """
  def filterAd(url, adRequest) do
    {:ok, ret} = HTTP.call(url, "filterAd", adRequest)
    ret
  end
end
