defmodule EbloxWeb.PostController do
  use EbloxWeb, :controller

  def show(conn, %{"id" => [<<_year::binary-size(4), ?-, _::binary>> = id]}) do
    html = html(id)
    render(conn, "show.html", content: html)
  end

  def show(conn, %{"id" => [id]}) do
    html = "texts" |> Path.join(id) |> html()
    render(conn, "show.html", content: html)
  end

  defp html(path) do
    case Siblings.payload(Eblox.Data.Content, "priv/test_content/" <> path) do
      %{html: html} -> html
      other -> "<b font-color='red'>#{inspect(other)}</b>"
    end
  end
end
