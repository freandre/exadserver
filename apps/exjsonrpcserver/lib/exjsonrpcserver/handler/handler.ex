defmodule ExJSONRPCServer.Handler do
  use JSONRPC2.Server.Handler

  def handle_request("hello", name) do
    "Hello, #{name}!"
  end

  def handle_request("filterAd", adRequest) do
    ExAdServer.filterAd(AdServer, adRequest)
  end
end
