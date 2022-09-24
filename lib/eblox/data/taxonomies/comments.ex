defmodule Eblox.Data.Taxonomies.Comments do
  @moduledoc """
  Data taxonomy implementation for post's comments tree.
  """

  alias Eblox.Data.{Post.Properties, Taxonomy}

  @behaviour Taxonomy

  @root_id "root"

  @impl Taxonomy
  def registry_options(opts \\ []) do
    Keyword.merge([keys: :duplicate, name: __MODULE__], opts)
  end

  @impl Taxonomy
  def on_add(registry, post_id) do
    parent_id = post_parent_id(post_id)

    registry
    |> Registry.register(parent_id, post_id)
    |> elem(0)
  end

  @impl Taxonomy
  def on_remove(registry, post_id) do
    parent_id = post_parent_id(post_id)

    Registry.unregister_match(registry, parent_id, post_id)
  end

  defp post_parent_id(post_id) do
    Siblings.payload(Eblox.Data.Content, post_id)
    |> Map.get(:properties, %Properties{})
    |> Map.get(:links, MapSet.new())
    |> MapSet.to_list()
    |> case do
      [parent_id] -> parent_id
      _ -> @root_id
    end
  end
end
