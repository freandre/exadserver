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

  @doc """
  Get a bag store from a registry and its name. If not available it is created
  and the registry updated
  """
  def getBagStore(name, indexes) do
    if Map.has_key?(indexes, name) == false do
      store = ETS.new(String.to_atom(name), [:bag])
      new_indexes = Map.put(indexes, name, store)
      {store, new_indexes}
    else
      {indexes[name], indexes}
    end
  end

  @doc """
  Get a set store from a registry and its name. If not available it is created
  and the registry updated
  """
  def getStore(name, indexes) do
    if Map.has_key?(indexes, name) == false do
      store = ETS.new(String.to_atom(name), [])
      new_indexes = Map.put(indexes, name, store)
      {store, new_indexes}
    else
      {indexes[name], indexes}
    end
  end
end
