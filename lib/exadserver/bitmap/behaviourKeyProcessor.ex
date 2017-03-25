defmodule  ExAdServer.Config.BehaviorKeysProcessor do
  # Prepare an index key
  @callback getIndexKey(any, any) :: any
end
