defmodule TwilixirBotWeb.Live.Index do
  use TwilixirBotWeb, :live_view
  alias TwilixirBot.Accounts

  @impl true
  def mount(_params, session, socket) do

    case session do
      %{"user_token" => user_token} ->
        user = Accounts.get_user_by_session_token(user_token)
        {:ok, assign(socket, :current_user, user)}
      _ ->
        {:ok, assign(socket, :current_user, nil)}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket}
  end
end
