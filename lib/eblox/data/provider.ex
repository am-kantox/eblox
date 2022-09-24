defmodule Eblox.Data.Provider do
  @moduledoc """
  The behaviour specifying the data provider to be plugged into `Eblox`.

  Data providers define how the data is collected from different data sources
    and mix the content into the whole content pool available to `Eblox`.
  """

  alias Eblox.Data.Provider

  @typedoc """
  URI of the resource, e. g. path to the file for file system
  """
  @type uri :: Path.t() | any()

  @typedoc """
  This struct contains information about changes found upon the consecutive scan
  """
  @type t :: %{__struct__: Provider, created: [uri()], deleted: [uri()], changed: [uri()]}

  @typedoc """
  Return values of post's process start action.
  """
  @type on_action_create ::
          :ok
          | {:error, {:already_started, pid()}}
          | {:error, :ignore | :max_children | :invalid_properties | term()}

  use Estructura, enumerable: true

  defstruct created: [], deleted: [], changed: []

  @doc """
  The providers must implement this callback returning the changes found
  """
  @callback scan(options :: map()) :: {map(), t()}

  @doc """
  The providers must implement this callback returning the initial post's payload
  """
  @callback initial_payload(term()) :: map()

  @fsm """
  idle --> |scan!| ready
  ready --> |scan| ready
  ready --> |stop| died
  """

  use Finitomata, fsm: @fsm, impl_for: [:on_transition, :on_enter]

  @impl Finitomata
  @doc false
  def on_transition(_, :scan!, _, payload) do
    # TODO Checks and proper error messages
    {impl, options} = Map.pop(payload, :impl)
    {options, %Provider{} = result} = impl.scan(options)

    handle_changes(impl, result)

    {:ok, :ready, Map.put(options, :impl, impl)}
  end

  @impl Finitomata
  @doc false
  def on_enter(:ready, %{payload: payload}) do
    payload
    |> Map.get(:listeners, [])
    |> Enum.each(&Process.send(&1, :on_ready, []))
  end

  @behaviour Siblings.Worker

  @impl Siblings.Worker
  @doc false
  def perform(:died, _id, payload), do: {:transition, :*, payload}
  def perform(_state, _id, payload), do: {:transition, :scan, payload}

  @spec handle_changes(module(), t()) :: :ok
  def handle_changes(impl, %Provider{created: _, deleted: _, changed: _} = changes) do
    changes
    |> Flow.from_enumerable()
    |> Flow.flat_map(fn {action, list} -> Enum.map(list, &{action, &1}) end)
    |> Flow.partition()
    |> Flow.reduce(fn -> [] end, fn {action, elem}, acc -> [action(impl, action, elem) | acc] end)
    |> Stream.run()
  end

  @interval Application.compile_env(:eblox, :parse_interval, 60_000)

  @spec action(Provider.t(), :created | :deleted | :changed, binary()) :: on_action_create()
  defp action(impl, :created, file) do
    with payload = %{} <- impl.initial_payload(file),
         :ok <-
           Siblings.start_child(Eblox.Data.Post, file, payload,
             name: Eblox.Data.Content,
             interval: @interval
           ) do
      :ok
    else
      {:ok, _server} ->
        :ok

      :ignore ->
        Logger.warn("[PROVIDER] Failed to start post: process ignored")
        {:error, :ignore}

      {:error, reason} ->
        Logger.warn("[PROVIDER] Failed to start post: " <> inspect(reason))
        {:error, reason}

      _ ->
        Logger.warn("[PROVIDER] Failed to start post: invalid initial properties")
        {:error, :invalid_properties}
    end
  end

  defp action(impl, :deleted, file) do
    Siblings.transition(Eblox.Data.Content, file, :delete, %{impl: impl})
  end

  defp action(impl, :changed, file) do
    Siblings.transition(Eblox.Data.Content, file, :parse, %{impl: impl})
  end
end
