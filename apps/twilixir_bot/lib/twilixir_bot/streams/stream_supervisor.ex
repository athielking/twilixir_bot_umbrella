defmodule TwilixirBot.Streams.StreamSupervisor do
  use DynamicSupervisor

  alias TwilixirBot.Streams.StreamWorker

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_stream(channel_name) do
    DynamicSupervisor.start_child(__MODULE__, {StreamWorker, %{channel_name: channel_name}})
  end
end
