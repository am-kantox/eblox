defmodule Eblox.Data.Taxonomies do
  @moduledoc false

  use Supervisor

  def start_link(taxonomies),
    do: Supervisor.start_link(__MODULE__, taxonomies)

  @impl Supervisor
  def init(children \\ []) do
    Supervisor.init(children, strategy: :one_for_one)
  end
end
