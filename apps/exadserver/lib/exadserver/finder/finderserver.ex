defmodule ExAdServer.Finder.FinderServer do
  require Logger

  use GenServer

  ## Client API

  @doc """
  Starts the finder.
  """
  def start_link(target_metadata) do
    GenServer.start_link(__MODULE__, target_metadata, [])
  end

  @doc """
  Main function for filtering ads based on received criteria

  Returns [ads] if something match or []
  In case of targeting argument not supported, :badArgument

  The send_to parameter is the PID to send data back to
  """
  def filterAd(server, ad_request, send_to) do
    GenServer.call(server, {:filter, ad_request, send_to})
  end

  ## Server Callbacks

  ## Init with the following metadata
  def init(target_metadata) do
    {:ok, [target_metadata: target_metadata]}
  end

  ## handle_call callback for :filter, performs some targeting based on a
  ## targeting request
  def handle_call({:filter, adRequest, send_to}, _from, state) do
    Logger.debug fn -> "[FinderServer] - Entering filter conf:\n #{inspect(adRequest)}" end
    target_metadata = state[:target_metadata]

    ret = Enum.reduce_while(target_metadata, :first,
      fn({indexName, indexProcessor, indexMetaData}, acc) ->
        set = indexProcessor.findInIndex(adRequest,
                                        {indexName, indexMetaData}, acc)
        checkMainStopCondition(set)
      end)

    Logger.debug fn -> "[adserver] - Exiting filter conf:\n #{inspect(ret)}" end
    GenServer.reply(send_to, ret)

    {:reply, ret, state}
  end

  ## Shall we stop to loop
  defp checkMainStopCondition([] = list), do: {:halt, list}
  defp checkMainStopCondition(list), do: {:cont, list}
end
