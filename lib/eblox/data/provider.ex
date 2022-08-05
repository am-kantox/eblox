defmodule Eblox.Data.Provider do
  @moduledoc """
  The behaviour sdpecifying the data provider to be plugged into `Eblox`.

  Data providers define how the data is collected from different data sources
    and mix the content into the whole content pool available to `Eblox`.
  """

  @typedoc """
  This struct contains information about changes found upon the consecutive scan
  """
  @type t :: %{
          __struct__: Eblox.Data.Provider,
          created: [],
          deleted: [],
          changed: []
        }

  defstruct created: [], deleted: [], changed: []

  @doc """
  The providers must implement this callback returning the changes found
  """
  @callback scan :: t()

  @fsm """
  idle --> |scan| ready
  ready --> |scan| ready
  ready --> |stop| died
  """

  use Finitomata, fsm: @fsm, impl_for: [:on_transition]

  @doc false
  def on_transition(_, :scan, _, payload) do
    # do_scan
    IO.inspect(payload, label: "PROVIDER")
    {:ok, :ready, payload}
  end

  @behaviour Siblings.Worker

  @impl Siblings.Worker
  @doc false
  def perform(:died, _id, payload), do: {:transition, :*, payload}
  def perform(_state, _id, payload), do: {:transition, :scan, payload}
end
