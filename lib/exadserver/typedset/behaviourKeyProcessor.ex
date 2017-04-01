defmodule  ExAdServer.TypedSet.BehaviorKeysProcessor do
  @moduledoc """
  Behaviour definition to fix common action for storing and retrieving
  data in indexes.
  """

  @doc """
  Prepare an index key or list of key
  first argument is a tuple ad configuration / bit index
  second argument is a tuple index name / index metadata
  third argument is the index registry
  returns the index registry as index can be added
  """
  @callback generateAndStoreIndex(Tuple.t, Tuple.t, Map.t) :: Map.t

  @doc """
  Perform a search in an index
  first argument is a targeting ad
  second argument is the bit index number to ad id store
  third argument a tuple containing the index name and its metadata
  fourth argument is the index registry
  returns a set of matching ad configuration for this index
  """
  @callback findInIndex(Map.t, PID.t, Tuple.t, Map.t) :: MapSet.t
end
