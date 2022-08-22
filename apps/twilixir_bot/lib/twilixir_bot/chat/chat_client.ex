defmodule TwilixirBot.Services.ChatClient do
  use WebSockex

  alias TwilixirBot.Services.Twitch
  alias Tesla
  alias Phoenix.PubSub

  def start_link(state) do
    irc_uri = Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_irc_uri]
    {:ok, pid} = WebSockex.start_link(irc_uri, __MODULE__, state)

    refresh_token = Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_bot_refresh_token]

    {:ok, %{"access_token" => access_token}} = Twitch.refresh_user_token(refresh_token)

    WebSockex.send_frame(pid, {:text, "PASS oauth:#{access_token}"})
    WebSockex.send_frame(pid, {:text, "NICK twilixir_bot"})

    {:ok, pid}
  end

  def handle_connect(_conn, state) do
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do

    IO.inspect state

    parsed_message = parse_message(msg)
    if parsed_message != :ignore do
      PubSub.broadcast(TwilixirBot.PubSub, "irc_message", {:irc_message, parsed_message})

      # if %{command: %{"command" => "PING"}, parameters: parameters} = parsed_message do
      #   IO.puts("Handling PING command")
      #   WebSockex.send_frame(state, {:text, "PONG #{parameters}"})
      # end
    end

    {:ok, state}
  end

  def join_channel(channel_name) do
    get_pid() |> WebSockex.send_frame({:text, "JOIN #{channel_name}"})
  end

  defp get_pid() do
    {_, pid, _, _} = Supervisor.which_children(TwilixirBot.Supervisor)
    |> Enum.find(fn child ->
      {module, _, type, _} = child
      module == __MODULE__ && type == :worker
    end)

    pid
  end

  # Message Parser
  def parse_message(message) do

    tag_str = if String.at(message, 0) == "@" do
      [tags | _] = message |> String.split(" ")
      tags
    end

    message = if tag_str do
      {_, remainder} = message |> String.split_at(String.length(tag_str))
      remainder |> String.trim()
    else
      message
    end

    source_str = if String.at(message, 0) == ":" do
      [source | _] = message |> String.split(" ")
      source
    end

    message = if source_str do
      {_, remainder} = message |> String.split_at(String.length(source_str))
      remainder |> String.trim()
    else
      message
    end

    [command_str, param_str | _ ] = message |> String.split(":")

    IO.puts "Tags: #{tag_str}"
    IO.puts "Source: #{source_str}"
    IO.puts "Command: #{command_str}"
    IO.puts "Parameters: #{param_str}"

    command = parse_command(command_str, param_str);

    case command do
      :ignore -> :ignore
      cmd -> %{
        tags: parse_tags(tag_str),
        source: parse_source(source_str),
        command: cmd,
        parameters: param_str
      }
    end
  end

  def parse_tags(tags) do
    if tags do
      tags
        |> String.trim_leading("@")
        |> String.split(";")
        |> Enum.filter(fn tag -> tag != "client-nonce" && tag != "flags" end)
        |> Enum.map( fn tag ->
          [key | [value|_]] = tag |> String.split("=")

          value = case value do
            "" -> nil
            _ -> value
          end

          handle_tag_key_and_value(key, value)
        end)
        |> Map.new
    else
      nil
    end
  end

  defp handle_tag_key_and_value(key, nil), do: {key, nil}
  defp handle_tag_key_and_value("badge-info", value), do: handle_tag_key_and_value("badge", value)
  defp handle_tag_key_and_value("badges"=key, value)do
    {key, Map.new(
          value
          |> String.split(",")
          |> Enum.map(fn badge ->
            [badge_name | [badge_value | _]] = badge |> String.split("/")

            {badge_name, badge_value}
          end)
      )}
  end

  defp handle_tag_key_and_value("emotes"=key, value) do
    {key, Map.new(
      value
        |> String.split("/")
        |> Enum.map(fn emote ->
          [emote_id | [positions | _]] = emote |> String.split(":")

          pos_list = positions
            |> String.split(",")
            |> Enum.map(fn pos ->
              [start_pos | [end_pos | _]] = pos |> String.split("-")
              %{"start_pos" => start_pos, "end_pos" => end_pos}
            end)

          {emote_id, pos_list}
        end)
    )}
  end

  defp handle_tag_key_and_value("emote-sets"=key, value) do
    {key, value
        |> String.split(",")
      }
  end

  defp handle_tag_key_and_value(key, value), do: {key, value}

  def parse_source(source) do
    if source do
      case source |> String.trim_leading(":") |> String.split("!") do
        [nick, host | _ ] -> %{"nick" => nick, "host" => host}
        [host] -> %{"nick" => nil, "host" => host}
        _ -> %{"nick" => nil, "host"=> source}
      end
    else
      nil
    end
  end

  def parse_command(command, params) do
    command_map = case command |> String.split(" ") do
      [cmd, _, ack | _] when cmd in ["CAP"] -> %{"command" => cmd, "isCapRequestEnabled" => ack == "ACK"}
      [cmd, channel | _] when cmd in ["JOIN", "PART", "NOTICE", "CLEARCHAT", "HOSTTARGET", "PRIVMSG", "USERSTATE", "ROOMSTATE", "001"] -> %{"command" => cmd, "channel" => channel}
      [cmd | _] when cmd in ["PING", "GLOBALUSERSTATE", "RECONNECT"] -> %{"command" => cmd}
      _ -> :ignore
    end

    if command_map != :ignore && String.at(params, 0) == "!" do
      [bot_command | _] = params |> String.split(" ")
      {_, bot_params} = params |> String.split_at(String.length(bot_command))

      command_map
        |> Map.put("bot_command", bot_command)
        |> Map.put("bot_params", String.trim(bot_params))
    else
      command_map
    end
  end
end
