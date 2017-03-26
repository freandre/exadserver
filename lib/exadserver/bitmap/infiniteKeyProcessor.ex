defmodule ExAdServer.Bitmap.InfiniteKeyProcessor do
  @behaviour ExAdServer.Config.BehaviorKeysProcessor

  ## Behaviour Callbacks

  def getIndexKeyForStorage(adConf, indexName,  _indexMetadata) do
    targeter = adConf["targeting"][indexName]["data"]
    inclusive = adConf["targeting"][indexName]["inclusive"]

    Enum.map(targeter, &({{inclusive, &1}, adConf["adid"]}))
  end
end
