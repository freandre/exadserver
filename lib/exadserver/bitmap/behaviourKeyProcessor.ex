defmodule  ExAdServer.Config.BehaviorKeysProcessor do
  ## Prepare an index key or list of key
  ## The first argument is the ad configuration, the second the index metadata,
  ## and finally the store registry. It returns the updated registry
  @callback generateAndStoreIndex(Map.t, Tuple.t, Map.t) :: Map.t

  ## Prepare the filter function to use in ets.select. The first argument is the
  ## indexx name, the second the associated data
  @callback filterIndex(String.t, any) :: any
end
