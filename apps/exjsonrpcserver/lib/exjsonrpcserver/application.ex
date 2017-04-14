defmodule ExJSONRPCServer.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    tcp_opts = generateTCPOptions()

    JSONRPC2.Servers.TCP.start_listener(ExJSONRPCServer.Handler, tcp_opts[:port], tcp_opts[:opts])
    JSONRPC2.Servers.HTTP.http(ExJSONRPCServer.Handler, generateHTTPOptions())
    
  end

  ## Private functions

  ## Read and generate options for HTTP handler
  defp generateHTTPOptions do
    data = Application.get_env(:exjsonrpcserver, HTTP)
    [acceptors: data[:num_acceptors]] ++
    [port: data[:port]]
  end

  ## Read and generate options for TCP handler
  defp generateTCPOptions do
    data = Application.get_env(:exjsonrpcserver, TCP)
    [opts: [num_acceptors: data[:num_acceptors]]] ++
    [port: data[:port]]
  end
end
