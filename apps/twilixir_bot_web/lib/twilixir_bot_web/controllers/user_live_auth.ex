defmodule TwilixirBotWeb.UserLiveAuth do
  import Phoenix.LiveView
  alias TwilixirBot.Accounts

  def on_mount(:default, _params, %{"user_token" => user_token} = _session, socket) do
    socket = assign_new(socket, :current_user, fn -> Accounts.get_user_by_session_token(user_token) end)

    if socket.assigns.current_user do
      socket = assign_new(socket, :user_refresh, fn -> Accounts.get_user_refresh_token(socket.assigns.current_user) end)
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end

  def on_mount(:bot_authorized, _params, %{"user_token" => user_token} = _session, socket) do
    socket = assign_new(socket, :current_user, fn -> Accounts.get_user_by_session_token(user_token) end)

    if socket.assigns.current_user do
      socket = assign_new(socket, :bot_refresh, fn -> Accounts.get_bot_refresh_token(socket.assigns.current_user) end)

      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end
end
