defmodule ExAdServer.Utils.Storage do
  @moduledoc """
  Storage helper module.
  """

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
    if ETS.info(store_name) != :undefined do
      IO.puts("FUUUUUUUUUUUUUUUUUUUUUCKKKK")
    else
      ETS.new(store_name, [:named_table])
    end
  end
end
