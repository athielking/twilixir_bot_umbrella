defmodule TwilixirBot.Streams.StreamWorker do
  use GenServer

  alias TwilixirBot.Services.Twitch
  alias Phoenix.PubSub

  def start_link(init_args) do
    %{channel_name: channel_name} = init_args

    GenServer.start_link(__MODULE__, init_args, name: via_tuple(channel_name))
  end

  def via_tuple(channel_name), do: {:via, Registry, {TwilixirBot.Registry, channel_name}}

  def init(init_args) do
    %{channel_name: channel_name} = init_args
    :ok = PubSub.subscribe(TwilixirBot.PubSub, "irc_message")

    case Twitch.get_app_token() do
      {:ok, %{"access_token" => access_token}} ->
        send(self(), :get_stream_info)
        send(self(), :join_channel)
        {:ok, Map.put(init_args, :access_token, access_token)}
      {:error, %{"message" => message, "status" => status}} -> {:ignore, "Failed to get twitch app access token: Status: #{status} - #{message}"}
    end
  end

  def get_state(channel_name) do
    via_tuple(channel_name)
      |> GenServer.call(:get_state)
  end

  # Callbacks
  def handle_info(:get_stream_info, state) do
    {:noreply, try_get_stream_info(state)}
  end

  def handle_info({:get_stream_info, retry_count}, state) do
    cond do
      #TODO: Make retry count configurable
      retry_count <= 3 -> {:noreply, try_get_stream_info(state, retry_count)}

      #Past the retries, just give up
      true -> {:noreply, Map.put(state, :stream_info, {:error, "Could Not Retrieve Stream Info"})}
      end
  end

  def handle_info({:irc_message, parsed_message}, state) do
    %{channel_name: channel_name} = state
    %{command: %{"command" => command, "channel" => channel}} = parsed_message

    if command == "PRIVMSG" && channel_name == channel do
      handle_privmsg(parsed_message)
    end

    {:noreply, state}
  end

  def handle_info(:join_channel, state) do
    %{channel_name: channel_name} = state

    TwilixirBot.Services.ChatClient.join_channel(channel_name)

    {:noreply, state}
  end

  defp try_get_stream_info(%{access_token: access_token, channel_name: channel_name} = state, retry_count \\ 0) do

    stream_resp = Twitch.api_client(access_token)
      |> Tesla.get("/streams?user_login=#{channel_name}")

    case stream_resp do
      # When we get stream info, add it to state and reply
      {:ok, %Tesla.Env{status: 200, body: %{"data" => [stream_info | _]}}} -> Map.put(state, :stream_info, stream_info)

      # If we dont get stream info retry a few times, the api lags slightly once stream goes online
      {:ok, %Tesla.Env{status: 200, body: %{"data" => []}}} ->
        Process.send_after(self(), {:get_stream_info, retry_count + 1}, 3_000)
        state

      # Some other error happened, just punt for now
      _ -> Map.put(state, :stream_info, {:error, "Error Retrieving Stream Info"})
      end
  end

  defp handle_privmsg(parsed_message) do
    IO.inspect parsed_message
  end

  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

end
