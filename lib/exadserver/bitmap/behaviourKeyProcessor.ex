defmodule  ExAdServer.Config.BehaviorKeysProcessor do
  ## Prepare an index key or list of key
  ## The first argument is the ad configuration, the second, the index name
  ## finally we should have an index metadata structure
  @callback getIndexKeyForStorage(Map.t, String.t,  any) :: any
end
