defmodule Eblox.Test.Messenger do
  @moduledoc false

  use GenServer

  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl GenServer
  def init([]), do: {:ok, []}

  @impl GenServer
  def handle_info({:listener, pid}, listeners) do
    {:noreply, [pid | listeners]}
  end

  @impl GenServer
  def handle_info(:on_ready, []) do
    Process.send_after(self(), :on_ready, 100)
    {:noreply, []}
  end

  @impl GenServer
  def handle_info(:on_ready, listeners) do
    for listener <- listeners, do: send(listener, :on_ready)
    {:noreply, listeners}
  end
end
