defmodule ExJSONRPCServer.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    tcp_opts = generate_tcp_options()

    JSONRPC2.Servers.TCP.start_listener(ExJSONRPCServer.Handler, tcp_opts[:port], tcp_opts[:opts])
    JSONRPC2.Servers.HTTP.http(ExJSONRPCServer.Handler, generate_http_options())

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: ExJSONRPCServer.Worker.start_link(arg1, arg2, arg3)
      # worker(ExJSONRPCServer.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExJSONRPCServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  ## Private functions

  ## Read and generate options for HTTP handler
  defp generate_http_options do
    data = Application.get_env(:exjsonrpcserver, HTTP)
    [acceptors: data[:num_acceptors]] ++
    [port: data[:port]]
  end

  ## Read and generate options for TCP handler
  defp generate_tcp_options do
    data = Application.get_env(:exjsonrpcserver, TCP)
    [opts: [num_acceptors: data[:num_acceptors]]] ++
    [port: data[:port]]
  end
end
