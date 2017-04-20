defmodule ExJSONRPCClientTCP do
  @moduledoc """
  Simple communication module to hit the TCP API
  """

  alias JSONRPC2.Clients.TCP

  @doc """
  Starts the server.
  """
  def start(host, port) do
   #Get the system tcp size
   {:ok, socket} = :gen_tcp.connect(String.to_charlist(host), port, [:binary, active: false])
   {:ok, values} = :inet.getopts(socket, [:recbuf, :sndbuf])
   :gen_tcp.close(socket)
    TCP.start(host, port, __MODULE__, [socket_options: [:binary, packet: :line, buffer: max(values[:recbuf], values[:sndbuf])]])
  end

  @doc """
  Stops the server.
  """
  def stop() do
    TCP.stop(__MODULE__)
  end

  @doc """
  Hello call to rpc server
  """
  def hello(name) do
    {:ok, ret} = TCP.call(__MODULE__, "hello", [name])
    IO.puts(ret)
  end

  @doc """
  Filter an ad generating a request
  """
  def filterAd(adRequest) do
    {:ok, ret} = TCP.call(__MODULE__, "filterAd", adRequest)    
  end
end
