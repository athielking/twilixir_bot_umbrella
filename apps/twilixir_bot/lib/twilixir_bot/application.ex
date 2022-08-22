defmodule TwilixirBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      TwilixirBot.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: TwilixirBot.PubSub},
      # Start the dynamic stream supervisor
      TwilixirBot.Streams.StreamSupervisor,
      #Start the registry to allow us to use :via tuples to name our processes
      {Registry, keys: :unique, name: TwilixirBot.Registry},
      {TwilixirBot.Services.ChatClient, %{}}

      # Start a worker by calling: TwilixirBot.Worker.start_link(arg)
      # {TwilixirBot.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: TwilixirBot.Supervisor)
  end
end
