defmodule ExAdServer.Utils.Storage do
  @moduledoc """
  Storage helper module.
  """

  require Logger
  alias :ets, as: ETS

  @doc """
  Helper function to print the content of an ets store
  """
  def dumpETS(ets_store) do
    IO.puts("Store: " <> Atom.to_string(ETS.info(ets_store)[:name]))
    ets_store
    |> ETS.match(:"$1")
    |> Enum.each(&IO.puts(inspect(&1)))
  end

  @doc """
  Helper function to retrieve a normalized index store
  """
  def getIxAtom(ix_name), do: String.to_atom(ix_name <> "_store")

  @doc """
  Helper function to create a named data store
  """
  def createStore(store_name) do
    Logger.debug "[storage] - Creating ETS store #{store_name}"
    {:ok, val} = Eternal.start(store_name, [:named_table, {:read_concurrency, true}])
    val
  end

  @doc """
  Helper function to create a named bag data store
  """
  def createBagStore(store_name) do
    Logger.debug "[storage] - Creating ETS store #{store_name}"
    {:ok, val} = Eternal.start(store_name, [:named_table, :bag, {:read_concurrency, true}])
    val
  end

  @doc """
  Helper function to delete a data store
  """
  def deleteStore(store_name) do
    Logger.debug "[storage] - Deleting ETS store #{store_name}"
    Eternal.stop(store_name)
  end
end
