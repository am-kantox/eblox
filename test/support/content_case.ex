defmodule Eblox.ContentCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the `Eblox` content provided by specific data providers
  and organized by specific taxonomies. The setup requires synchronous
  execution.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Eblox.ContentCase
    end
  end

  setup context do
    app = Mix.Project.config()[:app]

    Application.stop(app)

    providers = start_supervised!({Eblox.Data.Providers, Map.get(context, :providers, [])})
    taxonomies = start_supervised!({Eblox.Data.Taxonomies, Map.get(context, :taxonomies, [])})

    on_exit(fn -> Application.start(app) end)

    {:ok,
     providers: providers,
     taxonomies: taxonomies,
     content_name: Eblox.Data.Content,
     providers_name: Eblox.Data.Providers,
     taxonomies_name: Eblox.Data.Taxonomies}
  end
end
