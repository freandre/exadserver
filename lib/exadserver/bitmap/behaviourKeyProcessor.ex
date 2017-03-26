defmodule  ExAdServer.Config.BehaviorKeysProcessor do
  # Prepare an index key
  @callback getIndexKey(Map.t, String.t,  any) :: Tuple.t
end
