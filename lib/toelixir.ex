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
  def init([]) do
    :random.seed(:erlang.timestamp())
    {:once, %{role: nil, token: "me", name: "me", topic: "tictactoe:1"}}
  end

  def onconnect(_wsreq, state) do
    IO.puts "connected! time to send the first message"
    send_join_request(state)
    {:ok, state}
  end

 def ondisconnect(reason, state) do
    IO.puts "disconnected because #{inspect reason}"
    {:reconnect, state}
  end

  def websocket_handle({:text, msg}, _conn, state) do
    IO.puts "Recevied: #{msg}"
    IO.puts "State: #{inspect state}"
    msg = Poison.decode!(msg)
    case msg do
      %{"event" => "phx_reply", "payload" => %{"status" => "ok", "response" => %{"role" => assigned_role}}} ->
        {:ok, %{state | role: assigned_role}}
      %{"event" => "state", "payload" => payload} ->
        make_a_move(state, payload)
        {:ok, state}
      %{"event" => "game_over", "payload" => payload} ->
        IO.puts "the game is over man!"
        IO.inspect(payload)
        {:close, "game_over", state}
      _ ->
        {:ok, state}
    end
  end

  def websocket_info({:send, msg}, _connstate, state) do
    msg = Poison.encode!(msg)
    IO.puts "sending: #{msg}"
    {:reply, {:text, msg}, state}
  end

  def websocket_terminate(reason, _connstate, state) do
    IO.puts "Websocket closed #{inspect reason}"
    IO.inspect state
    :ok
  end

  # Private Methods
  defp make_a_move(%{token: token, topic: topic}, %{"board" => board}) do
    square = pick_square_to_play(board)
    msg = %{topic: topic, event: "move", ref: 2, payload: %{token: token, square: square}}
    send self, {:send, msg}
  end

  defp send_join_request(%{token: token, name: name, topic: topic}) do
    msg = %{topic: topic, event: "phx_join", ref: 1, payload: %{token: token, name: name}}
    send self, {:send, msg}
  end

  def pick_square_to_play(board) do
    playable_squares(board) |> Enum.shuffle |> List.first
  end

  def playable_squares(board) do
    Enum.with_index(board)
      |> Enum.filter(fn({nil, _idx}) -> true
                       (_) -> false end)
      |> Enum.map fn({nil,idx}) -> idx end
  end
end
