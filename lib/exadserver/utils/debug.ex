defmodule ExAdServer.Utils.Debug do
  alias :ets, as: ETS

  ## Utility function to dump the content of a store
  defp dumpETS(etsStore) do
    IO.puts("Store: " <> Atom.to_string(ETS.info(etsStore)[:name]))
    ETS.match(etsStore, :"$1")
    |> Enum.each(&IO.puts(inspect(&1)))
  end
end
