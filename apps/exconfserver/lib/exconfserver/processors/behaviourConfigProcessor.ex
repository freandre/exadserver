defmodule  ExConfServer.Processors.BehaviorConfigProcessor do
  @moduledoc """
  Behaviour declaration to fix common action for configuration micro service.
  """

  @doc """
  Init with a single parameter
  """
  @callback init(any) :: any

  @doc """
  Find an conf by state / id
  :all can be provided to get a full list
  """
  @callback getConf(any, String.t | Atom.t) :: any

  @doc """
  Get target metadata based on state / target name
  :all can be provided to get a full list of {target name / metadata}
  """
  @callback getMetadata(any, String.t | Atom.t) :: any

  @doc """
  Cleanup task
  """
  @callback cleanup() :: any
end
