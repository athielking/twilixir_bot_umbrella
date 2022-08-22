defmodule TwilixirBotWeb.LoginLive.Index do
  use TwilixirBotWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do

    client_id = Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_client_id]
    redirect_uri = Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_redirect_uri]

    twitch_url = "https://id.twitch.tv/oauth2/authorize?client_id=#{client_id}&redirect_uri=#{redirect_uri}&response_type=code&scope=user%3Aread%3Aemail"

    socket = assign(socket, current_user: nil)
    {:ok, assign(socket, twitch_url: twitch_url)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket}
  end
end
