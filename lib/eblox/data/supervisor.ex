defmodule Eblox.Data.Providers do
  @moduledoc false
  use Supervisor

  @default_interval Application.compile_env(:eblox, :provider_interval, 5_000)

  def start_link(providers),
    do: Supervisor.start_link(__MODULE__, providers)

  @impl Supervisor
  def init(providers) do
    children = [
      Siblings.child_spec(name: Eblox.Data.Providers)
      # {Eblox.Data.Monitor, content: providers}
    ]

    children
    |> Supervisor.init(strategy: :rest_for_one)
    |> tap(fn _ ->
      Task.start(fn ->
        Process.sleep(1_000)

        Enum.each(providers, fn {worker, {impl, opts}} ->
          {id, opts} = Keyword.pop(opts, :id, worker)
          {interval, opts} = Keyword.pop(opts, :interval, @default_interval)

          Siblings.start_child(worker, id, Keyword.put(opts, :impl, impl),
            name: Eblox.Data.Providers,
            interval: interval
          )
        end)
      end)
    end)
  end
end
