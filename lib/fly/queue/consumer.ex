defmodule Fly.Queue.Consumer do
  use GenServer
  use AMQP

  alias Fly.Queue.Worker

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient,
      shutdown: 5000,
      type: :worker
    }
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @queue "invoices_due_today"

  def init(_opts) do
    IO.puts("consumer process starting...")

    with {:ok, connection} <- AMQP.Connection.open(Application.get_env(:fly, :amqp)),
         {:ok, channel} <- AMQP.Channel.open(connection) do
      {:ok, _consumer_tag} = Basic.consume(channel, @queue)

      {:ok, channel}
    else
      {:error, reason} ->
        IO.puts("Failed to start queue: #{reason}")
        {:stop, reason}
    end
  end

  def handle_info({:basic_deliver, payload, meta}, channel) do
    IO.puts("Received message: #{payload}")
    Worker.handle_message(payload)
    IO.puts("acking...")
    Basic.ack(channel, meta.delivery_tag)
    {:noreply, channel}
  end

  def handle_info({:basic_consume_ok, _}, channel) do
    IO.puts("Consumer registered.")
    {:noreply, channel}
  end
end
