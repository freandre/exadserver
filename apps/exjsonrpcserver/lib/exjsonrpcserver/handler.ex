defmodule ExJSONRPCServer.Handler do
  @moduledoc """
  Simple handler for tcp and http
  """

  require Logger
  use JSONRPC2.Server.Handler

  @doc """
  Simple hello test handler
  """
  def handle_request("hello", name) do
    Logger.debug "[handler] - Received an hello request: #{name}"
    "Hello, #{name}!"
  end

  @doc """
  Filtering ad handler taking an ad request and returning a list of ad configuration id
  """
  def handle_request("filterAd", adRequest) do
    Logger.debug "[handler] - Received a filterAd request:\n #{inspect(adRequest)}"
    ExAdServer.filterAd(AdServer, adRequest)
  end
end
