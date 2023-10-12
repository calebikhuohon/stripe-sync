defmodule Fly.Queue.Worker do
  def handle_message(message) do
    IO.puts("Received message: #{message}")
    Fly.sync_single_invoice(message)
  end
end
