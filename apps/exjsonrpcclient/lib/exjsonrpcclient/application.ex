defmodule ExJSONRPCClient.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    #ExJSONRPCClient.start(Application.get_env(:exjsonrpcclient, :address), Application.get_env(:exjsonrpcclient, :port))

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Exjsonrpcclient.Worker.start_link(arg1, arg2, arg3)
      # worker(Exjsonrpcclient.Worker, [arg1, arg2, arg3]),
      Task.start(fn ->
                  ExJSONRPCClient.start(Application.get_env(:exjsonrpcclient, :address),
                                        Application.get_env(:exjsonrpcclient, :port))
                 end)
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExJSONRPCClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
