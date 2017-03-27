defmodule ExAdServer.Bitmap.FiniteKeyProcessor do
  @behaviour ExAdServer.Config.BehaviorKeysProcessor

  alias :ets, as: ETS

  use Bitwise

  ## Behaviour Callbacks
  def generateAndStoreIndex(adConf, {indexName, indexMetadata}, indexes) do
    {store, indexes} = ExAdServer.Utils.Storage.getStore(indexName, indexes)

    {key, _size} = Enum.reduce(indexMetadata, {0, 0},
                              fn({name, values}, acc) ->
                                encodeSingleTarget(adConf["targeting"][name],
                                                   values["distinctvalues"])
                                |> aggregateAccumulators(acc)
                              end)
    ETS.insert(store, {key, adConf["adid"]})
    indexes
  end

  ## Private functions

  ## Encode a single target, the first argument is one of the targeting attribute
  ## the seconde the associated distinct values for this attribute
  defp encodeSingleTarget(targeter, metadata) do
    cond do
    targeter == nil -> generateAll(length(metadata))
    targeter["data"] == "all" -> generateAll(length(metadata))
                                 |> excludeIfNeeded(targeter["inclusive"])
    true -> Enum.reduce(metadata, {0, 0},
                     fn(val, acc) ->
                       cond do
                         val in targeter["data"] -> addOne(acc)
                         true -> addZero(acc)
                       end
                     end)
            |> excludeIfNeeded(targeter["inclusive"])
    end
  end

  ## Generate a tuple {data, size} of 1's of size size
  defp generateAll(size) when size >= 0 do
    {generateOne(0, size), size}
  end

  ## Generate a tuple {data, size} of 1's of size size by shifting data
  defp generateOne(data, size) do
    case size do
      0 -> data
      _ -> generateOne((data <<< 1) ||| 1, size - 1)
    end
  end

  ## Aggregator for tuple {data, size}
  defp aggregateAccumulators({firstData, firstSize}, {secData, secSize}) do
    {generateOne(firstData, secSize) &&& secData, firstSize + secSize}
  end

  ## Negate the data of the tuple is inclusive is false
  defp excludeIfNeeded({data, size} = value, inclusive) do
    case inclusive do
      false -> {~~~data, size}
      _ -> value
    end
  end

  ## Add a 1 bit
  defp addOne({data, size}) do
    {(data <<< 1) ||| 1, size + 1}
  end

  ## Add a 0 bit
  defp addZero({data, size}) do
    {(data <<< 1), size + 1}
  end
end
