defmodule TwilixirBotWeb.AppLive.Index do
  use TwilixirBotWeb, :live_view
  on_mount TwilixirBotWeb.UserLiveAuth

  alias TwilixirBot.Services.Twitch
  alias Tesla

  @impl true
  def mount(_params, session, socket) do

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("join_channel", _payload, socket) do

    if !(socket.assigns |> Map.has_key?(:user_access)) do
      {:ok, %{"access_token" => access_token}} = Twitch.refresh_user_token(socket.assigns.user_refresh)
      ^socket = assign(socket, user_access: access_token)
    end

    {:ok, _pid} = TwilixirBot.Streams.StreamSupervisor.start_stream("##{socket.assigns.current_user.display_name}")
    {:noreply, socket}
  end

end
