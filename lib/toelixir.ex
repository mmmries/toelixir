defmodule Toelixir do
  @behaviour :websocket_client

  def start_link do
    #start_link("ws://games.riesd.com/socket/websocket?vsn=1.0.0")
    start_link('wss://echo.websocket.org')
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
    send self, :start
    {:ok, state}
  end

  def ondisconnect({:remote,:closed}, state) do
    IO.puts "disconnected because the remote closed, reconnecting now"
    {:reconnect, state}
  end

  def websocket_handle({:pong, msg}, _conn, state) do
    IO.puts "Received pong! #{inspect msg} (#{inspect state})"
    {:ok, state}
  end

  def websocket_handle({:text, msg}, _conn, 5) do
    IO.puts "Received text! #{inspect msg} (5)"
    {:close, "", 'done'}
  end

  def websocket_handle({:text, msg}, _conn, state) do
    IO.puts "Received text! #{inspect msg} (#{state})"
    :timer.sleep(1000)
    {:reply, {:text, "hello, this is message #{state}"}, state + 1}
  end

  def websocket_info(:start, _connstate, state) do
    IO.puts "going to start #{state}"
    {:reply, {:text, "hello, this is message #{state}"}, state}
  end

  def websocket_terminate(reason, _connstate, state) do
    IO.puts "Websocket closed #{inspect reason}"
    IO.inspect state
    :ok
  end
end
