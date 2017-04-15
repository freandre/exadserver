defmodule  ExAdServer.Indexes.BehaviorKeysProcessor do
  @moduledoc """
  Behaviour definition to fix common action for storing and retrieving
  data in indexes.
  """

  @doc """
  Prepare the metadata according to index type
  first argument is the raw metadata from config
  returns a list of metadata object and processor
  """
  @callback generateMetadata(Map.t) :: List.t

  @doc """
  Prepare an index key or list of key
  first argument is a tuple ad configuration / bit index
  second argument is a tuple index name / index metadata
  returns the index registry as index can be added
  """
  @callback generateAndStoreIndex(Tuple.t, Tuple.t) :: Map.t

  @doc """
  Perform a search in an index
  first argument is a targeting ad
  second argument a tuple containing the index name and its metadata
  third argument is a MapSet accumulator
  returns a set of matching ad configuration for this index
  """
  @callback findInIndex(Map.t, Tuple.t, MapSet.t) :: MapSet.t

  @doc """
  Clean data
  first argument is index name
  second argument is index metadata
  """
  @callback cleanup(String.t, Map.t) :: any
end
