defmodule ExAdServer.Bitmap.InfiniteKeyProcessor do
  @behaviour ExAdServer.Config.BehaviorKeysProcessor

  alias :ets, as: ETS

  ## Behaviour Callbacks

  def generateAndStoreIndex(adConf, {indexName, _indexMetadata}, indexes) do
    {store, indexes} = ExAdServer.Utils.Storage.getStore(indexName, indexes)

    targeter = adConf["targeting"][indexName]["data"]
    inclusive = adConf["targeting"][indexName]["inclusive"]

    ETS.insert(store, Enum.map(targeter, &({{inclusive, &1}, adConf["adid"]})))

    indexes
  end

  def getFilterForETSSelect(indexName, indexMetadata) do

  end
end
