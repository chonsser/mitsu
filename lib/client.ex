defmodule Mitsu.Client do
  require Logger
  use WebSockex

  def start_link(state) do
    {:ok, connection} = AMQP.Connection.open([
      host: state["amqp_conn_details"]["host"],
      username: state["amqp_conn_details"]["username"],
      password: state["amqp_conn_details"]["password"],
      heartbeat: state["amqp_conn_details"]["heartbeat"],
      connection_timeout: state["amqp_conn_details"]["timeout"]
    ], state["amqp_conn_details"]["conn_name"])
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Queue.declare(channel, state["amqp_conn_details"]["event_channel"])

    state = Map.put(state, "amqp_conn", connection)
    state = Map.put(state, "amqp_channel", channel)

    Logger.info("Connecting to #{state["gateway_url"]}")
    WebSockex.start_link(state["gateway_url"], __MODULE__, state)
  end

  def handle_connect(_connection, state) do
    Logger.info("Connected")
    {:ok, state}
  end

  def handle_frame({:binary, frame}, state) do
    decoded = :erlang.binary_to_term(frame)

    if decoded.s != nil do
      state = Map.put(state, "seq", decoded.s)
    end

    {st, action} = case decoded.op do
      0  -> handle_event(state, decoded)
      1  -> handle_hb(state, decoded.d)
      9  -> handle_invalid(state, decoded.d)
      10 -> handle_hello(state, decoded.d)
      11 -> handle_hb_ack(state)

      _  -> handle_unknown(state, decoded)
    end

    if action != nil do
      case action do
        {:reply, data} -> {:reply, {:binary, :erlang.term_to_binary(data)}, st}
        {:close, reason} -> terminate(reason, st)
      end
    else
      {:ok, st}
    end
  end

  def handle_frame(frame, state) do
    Logger.info("Got unknown type frame: #{inspect frame}")
    
    {:ok, state}
  end

  def handle_event(state, decoded) do
    event = %{
      "type" => Atom.to_string(decoded.t),
      "shard_id" => state["shard"],
      "data" => decoded.d
    }

    AMQP.Basic.publish(state["amqp_channel"], "", state["amqp_conn_details"]["event_channel"], :erlang.term_to_binary(event))

    {state, nil}
  end

  def handle_hb(state, data) do
    Logger.info("Heartbeat[seq=#{data}]")
    {state, nil}
  end

  def handle_invalid(state, data) do
    Logger.info("Invalid[is_resumable=#{data}]")
    {state, {:close, "Invalidated session"}}
  end

  def handle_hello(state, data) do
    Logger.info("Hello[heartbeat_interval=#{data.heartbeat_interval}]")

    Process.send_after(self(), :heartbeat, data.heartbeat_interval)

    to_send = %{
      "op" => 2,
      "d" => %{
        "token" => state["token"],
        "shard" => [state["shard"], state["max_shards"]],
        "properties" => state["conn_properties"]
      }
    }

    state = Map.put(state, "hb_interval", data.heartbeat_interval)

    {state, {:reply, to_send}}
  end

  def handle_hb_ack(state) do
    Logger.info("Heartbeat_ACK[]")
    {state, nil}
  end

  def handle_unknown(state, decoded) do
    Logger.info("Payload[opcode=#{decoded.op},data=#{inspect(decoded.d)},s=#{decoded.s},t=#{decoded.t}]")
    {state, nil}
  end

  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
  end

  def handle_info(:heartbeat, state) do
    to_send = %{
      "op" => 1,
      "d" => state["seq"]
    }

    Process.send_after(self(), :heartbeat, state["hb_interval"])
    {:reply, {:binary, :erlang.term_to_binary(to_send)}, state}
  end

  def handle_disconnect(%{reason: reason}, state) do
    Logger.info("Disconnected: #{inspect(reason)}")

    {:ok, state}
  end

  def terminate(reason, state) do
    AMQP.Channel.close(state["amqp_channel"])
    state = Map.put(state, "amqp_channel", nil)
    AMQP.Connection.close(state["amqp_conn"])
    state = Map.put(state, "amqp_conn", nil)

    Logger.info("Terminated: #{reason}")
    exit(:normal)
  end

end
