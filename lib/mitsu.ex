defmodule Mitsu do
  require Logger
  use Application

  def start(_type, _args) do
    children = []

    case get_gateway("https://discordapp.com/api/v6/gateway/bot") do
      {:ok, response} ->
        props = []
        template = %{
          "amqp_conn_details" => %{
            "host" => System.get_env("AMQP_HOST"),
            "username" => System.get_env("AMQP_USER"),
            "password" => System.get_env("AMQP_PASSWORD"),
            "event_channel" => "events",
            "heartbeat" => 5,
            "timeout" => 5000,
            "conn_name" => "gateway"
          },
          "shard" => nil,
          "max_shards" => response["shards"],
          "amqp_conn" => nil,
          "amqp_channel" => nil,
          "token" => System.get_env("DISCORD_TOKEN"),
          "gateway_url" => response["url"] <> "?v=6&encoding=etf",
          "seq" => nil,
          "hb_interval" => nil,
          "conn_properties" => %{
            "$os" => "unknown",
            "$browser" => "mitsu",
            "$device" => "unknown"
          }
        }

        props = ShardLoop.loop(response["shards"], template, props)
        children = ChildrenLoop.loop(props, children)

        start_client(children)
      {:error, reason} ->
        Logger.info("Failed to get gateway URL and shard count. Reason: #{reason}")
    end
  end

  def start() do
    start(:a, :a)
  end

  def get_gateway(url) do
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 500]
    token = System.get_env("DISCORD_TOKEN")
    headers = ["Authorization": "Bot #{token}", "Accept": "Application/json; Charset=utf-8"]
    
    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}
      {:ok, %HTTPoison.Response{status_code: 400}} -> {:error, "Bad request"}
      {:ok, %HTTPoison.Response{status_code: 401}} -> {:error, "Unauthorized"}
      {:ok, %HTTPoison.Response{status_code: 403}} -> {:error, "Forbidden"}
      {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, "Not found"}
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
    end
  end

  def start_client(children) do
    Supervisor.start_link(children, strategy: :one_for_one)
  end
  
end

defmodule ShardLoop do

  def loop(times_left, _template, object) when times_left <= 0 do
    object
  end

  def loop(times_left, template, object) do
    to_add = Map.put(template, "shard", times_left - 1)
    object = object ++ [to_add]
    loop(times_left - 1, template, object)
  end
  
end

defmodule ChildrenLoop do

  def loop(options_list, object) when length(options_list) <= 0 do
    object
  end

  def loop(options_list, object) do
    [head | tail] = options_list

    object = object ++ [{Mitsu.Client, head}]
    loop(tail, object)
  end
  
end
