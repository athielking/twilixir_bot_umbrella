defmodule TwilixirBotWeb.OauthController do
  use TwilixirBotWeb, :controller
  alias TwilixirBot.Services.Twitch
  alias TwilixirBot.Accounts
  alias TwilixirBotWeb.UserAuth

  @spec callback(Plug.Conn.t(), map) :: Plug.Conn.t()
  def callback(conn, %{"code" => code, "scope" => scope} = params) do

     handled = Twitch.get_user_token(code)
     |> handle_token_response()

     case handled do
       {:error, _} ->
        put_flash(conn, :error, "Failed to authenticate with Twitch")
        redirect(conn, to: "/")
       {:ok, user} ->
        put_flash(conn, :info, "Logged In")
        UserAuth.log_in_user(conn, user, %{"remember_me" => "true"})
     end
  end

  def callback(conn, %{"error" => error, "error_message" => error_message} = params) do
    redirect(conn, to: "/error")
  end

  defp handle_token_response({:ok, body} = _resp) do
    %{"access_token" => access_token, "refresh_token" => refresh_token} = body

    IO.inspect(body)

    {:ok, user} = Twitch.api_client(access_token)
    |> Tesla.get!("/users")
    |> handle_user_response

    TwilixirBot.Accounts.store_user_refresh_token(user, %{"refresh_token" => refresh_token})
  end

  defp handle_token_response(_resp) do
    IO.puts "ERROR"
  end

  defp handle_user_response(%Tesla.Env{status: 200, body: body}) do
      %{"data" => [user_data | _]} = body
      id = user_data["id"]

      if user = Accounts.get_user_by_external_id(id) do
        {:ok, user}
      else
        attrs = %{email: user_data["email"], external_id: user_data["id"], display_name: user_data["display_name"], external_id_source: "twitch"}
        Accounts.register_user_external(attrs)
      end
  end

  defp handle_user_response(_resp) do

  end
end
