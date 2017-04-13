defmodule ExConfServer.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    initData = getInitData()

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Exconfserver.Worker.start_link(arg1, arg2, arg3)
      # worker(Exconfserver.Worker, [arg1, arg2, arg3]),
      worker(ExConfServer, [ConfServer, initData])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExConfServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  ## Private functions

  ## Check in configuration if there is a testing value, if so use it in priority
  ## instead of DB connection
  defp getInitData do
    data = Application.get_env(:exconfserver, Testing)
    if data != nil do
      {data[:distinctPath], data[:numberOfConf]}
    else
      Application.get_env(:exconfserver, DBConnection)
    end
  end
end
