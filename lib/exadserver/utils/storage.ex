defmodule ExAdServer.Utils.Storage do
  alias :ets, as: ETS

  @doc """
  Helper function to print the content of an ets store
  """
  def dumpETS(etsStore) do
    IO.puts("Store: " <> Atom.to_string(ETS.info(etsStore)[:name]))
    ETS.match(etsStore, :"$1")
    |> Enum.each(&IO.puts(inspect(&1)))
  end

  ## Return a a store based on index name, instanciate it if it does not exists
  ## thus needing to return also the store registry
  def getStore(indexName, indexes) do
    if !Map.has_key?(indexes, indexName) do
      store = ETS.new(String.to_atom(indexName), [:bag, :protected])
      newIndexes = Map.put(indexes, indexName, store)
      {store, newIndexes}
    else
      {indexes[indexName], indexes}
    end
  end
end
