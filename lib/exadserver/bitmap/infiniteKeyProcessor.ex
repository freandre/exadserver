defmodule ExAdServer.Bitmap.InfiniteKeyProcessor do
  @behaviour ExAdServer.Config.BehaviorKeysProcessor

  ## Behaviour Callbacks

  def getIndexKey(ad, indexName,  indexMetadata) do
    {}
  end
end
