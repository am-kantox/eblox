defmodule Eblox.Data.Taxonomy do
  @moduledoc false

  use Supervisor

  @type post_id() :: Siblings.Worker.id()
  @type registry_option() :: Registry.start_option()

  @callback registry_options([registry_option()]) :: [registry_option()]
  @callback on_add(module(), post_id(), term()) :: :ok | :error
  @callback on_remove(module(), post_id()) :: :ok

  defmodule Meta do
    @moduledoc false

    use Agent

    alias Eblox.Data.Taxonomy.Meta

    @type t :: %{
            __struct__: Meta,
            impl: module()
          }
    @enforce_keys ~w|impl|a
    defstruct ~w|impl|a

    def start_link(opts) do
      {impl, opts} = Keyword.pop!(opts, :impl)

      Agent.start_link(fn -> %Meta{impl: impl} end, opts)
    end

    def impl(name) do
      Agent.get(name, & &1.impl)
    end
  end

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts)

  def init(opts) do
    {impl, opts} = Keyword.pop!(opts, :impl)
    {name, _opts} = Keyword.pop(opts, :name, impl)

    children = [
      {Meta, impl: impl, name: meta_name(name)},
      {Registry, impl.registry_options(name: reg_name(name))}
      # {PubSub, name: pubsub_name(name)}
    ]

    Supervisor.init(children, name: sup_name(name), strategy: :one_for_one)
  end

  def add(name, post_id, value \\ nil) do
    impl(name).on_add(reg_name(name), post_id, value)
  end

  def remove(name, post_id) do
    impl(name).on_remove(reg_name(name), post_id)
  end

  def lookup(name, key) do
    Registry.lookup(reg_name(name), key)
  end

  defp impl(name) do
    name
    |> meta_name()
    |> Meta.impl()
  end

  defp sup_name(name), do: Module.concat(name, "Supervisor")
  defp meta_name(name), do: Module.concat(name, "Meta")
  defp reg_name(name), do: Module.concat(name, "Registry")
end
