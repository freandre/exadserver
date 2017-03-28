defmodule ExAdServer.Utils.Storage do
  @moduledoc """
  Storage helper module.
  """

  alias :ets, as: ETS

  @doc """
  Helper function to print the content of an ets store
  """
  def dumpETS(etsStore) do
    IO.puts("Store: " <> Atom.to_string(ETS.info(etsStore)[:name]))
    etsStore
    |> ETS.match(:"$1")
    |> Enum.each(&IO.puts(inspect(&1)))
  end

  ## Return a a store based on index name, instanciate it if it does not exists
  ## thus needing to return also the store registry
  def getStore(indexName, indexes) do
    if Map.has_key?(indexes, indexName) == false do
      store = ETS.new(String.to_atom(indexName), [:bag, :protected])
      new_indexes = Map.put(indexes, indexName, store)
      {store, new_indexes}
    else
      {indexes[indexName], indexes}
    end
  end
end
