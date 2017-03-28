defmodule ExAdServer.Utils.Debug do
  @moduledoc """
  Debug helper module.
  """

  alias :ets, as: ETS

  ## Utility function to dump the content of a store
  defp dumpETS(etsStore) do
    IO.puts("Store: " <> Atom.to_string(ETS.info(etsStore)[:name]))
    etsStore
    |> ETS.match(:"$1")
    |> Enum.each(&IO.puts(inspect(&1)))
  end
end
