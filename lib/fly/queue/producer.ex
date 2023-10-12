defmodule Fly.Queue.Producer do
  use GenServer

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

  @queue_name "invoices_due_today"

  def init(:ok) do
    IO.puts("Producer starting...")

    with {:ok, connection} <- AMQP.Connection.open(Application.get_env(:fly, :amqp)),
         {:ok, channel} <- AMQP.Channel.open(connection) do
      case AMQP.Queue.declare(channel, @queue_name, durable: true) do
        {:ok, _} ->
          IO.puts("Producer started...")

          {:ok, %{channel: channel}}

        {:error, reason} ->
          IO.puts("Failed to declare queue: #{reason}")
          {:stop, reason}
      end
    else
      {:error, reason} ->
        IO.puts("Failed to start queue: #{reason}")
        {:stop, reason}
    end
  end

  def get_channel do
    IO.puts("Getting channel...")
    GenServer.call(__MODULE__, :get_channel)
  end

  def handle_call(:get_channel, _from, %{channel: channel} = state) do
    IO.puts("Returning channel...")
    {:reply, channel, state}
  end

  def handle_call(
        {:publish, %Fly.Billing.Invoice{} = invoice},
        _from,
        %{channel: channel} = state
      ) do
    # Handle the invoice struct as needed
    IO.puts("Publishing invoice...")
    data = Jason.encode!(invoice)
    AMQP.Basic.publish(channel, "", @queue_name, data)
    IO.puts("published invoice #{invoice.id}")
    {:reply, :ok, state}
  end

  def publish(message) do
    GenServer.call(__MODULE__, {:publish, message})
  end
end
