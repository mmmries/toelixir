defmodule Toelixir do
  @behaviour :websocket_client

  def start_link do
    start_link('ws://games.riesd.com/socket/websocket?vsn=1.0.0')
  end
  def start_link(uri) do
    :crypto.start()
    :ssl.start()
    :websocket_client.start_link(uri, __MODULE__, [])
  end

  # Callbacks
  def init([]), do: {:once, 1}

  def onconnect(_wsreq, state) do
    IO.puts "connected! time to send the first message"
    {:ok, state}
  end

 def ondisconnect(reason, state) do
    IO.puts "disconnected because #{inspect reason}"
    {:reconnect, state}
  end

  def websocket_handle({:text, msg}, _conn, state) do
    IO.puts "Received text! #{inspect msg} (#{state})"
    {:ok, state}
  end

  def websocket_info({:send, msg}, _connstate, state) do
    IO.puts "sending #{inspect msg}"
    {:reply, {:text, Poison.encode!(msg)}, state}
  end

  def websocket_terminate(reason, _connstate, state) do
    IO.puts "Websocket closed #{inspect reason}"
    IO.inspect state
    :ok
  end
end
