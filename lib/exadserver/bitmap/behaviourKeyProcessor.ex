defmodule  ExAdServer.Config.BehaviorKeysProcessor do
  # Prepare an index key
  # :all can be provided to get a full list
  @callback getIndexKey(any, any) :: any
end
