defmodule TwilixirBot.Services.Twitch do
  alias Tesla

  def get_user_token(auth_code) do

    body = %{
      "client_id" => Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_client_id],
      "client_secret" => Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_client_secret],
      "grant_type" => "authorization_code",
      "redirect_uri" => Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_redirect_uri],
      "code" => auth_code
    }

    token_resp = Tesla.client([
      Tesla.Middleware.EncodeFormUrlencoded,
      Tesla.Middleware.DecodeJson
    ])
    |> Tesla.post("https://id.twitch.tv/oauth2/token", body)

    IO.inspect token_resp

    case token_resp do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{status: _, body: body}} -> {:error, body}
      _ -> {:error, "Unknown Response"}
    end
  end

  def refresh_user_token(refresh_token) do
    body = %{
      "client_id" => Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_client_id],
      "client_secret" => Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_client_secret],
      "grant_type" => "refresh_token",
      "refresh_token" => refresh_token
    }

    token_resp = Tesla.client([
      Tesla.Middleware.EncodeFormUrlencoded,
      Tesla.Middleware.DecodeJson
    ])
    |> Tesla.post("https://id.twitch.tv/oauth2/token", body)

    case token_resp do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{status: _, body: body}} -> {:error, body}
      _ -> {:error, "Unknown Response"}
    end

  end

  def get_app_token() do
    body = %{
      "client_id" => Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_client_id],
      "client_secret" => Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_client_secret],
      "grant_type" => "client_credentials"
    }

    token_resp = Tesla.client([
      Tesla.Middleware.EncodeFormUrlencoded,
      Tesla.Middleware.DecodeJson
    ])
    |> Tesla.post("https://id.twitch.tv/oauth2/token", body)

    case token_resp do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{status: _, body: body}} -> {:error, body}
      _ -> {:error, "Unknown Response"}
    end
  end

  def api_client(token) do

    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.twitch.tv/helix"},
      {Tesla.Middleware.Headers,
        [
          {"Client-Id", Application.get_env(:twilixir_bot, TwilixirBot.Services)[:twitch_client_id]}
        ]
      },
      Tesla.Middleware.JSON,
      {Tesla.Middleware.BearerAuth, token: token}
    ]

    Tesla.client(middleware)
  end
end
