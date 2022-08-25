defmodule Eblox.Data.TaxonomyTest do
  use Eblox.ContentCase

  @provider Eblox.Data.Providers.FileSystem
  @taxonomy Eblox.Data.Taxonomies.Comments
  @content_dir "test/fixtures/comments_content"

  @moduletag providers: [
               {Eblox.Data.Provider, impl: @provider, content_dir: @content_dir}
             ],
             taxonomies: [
               {Eblox.Data.Taxonomy, impl: @taxonomy}
             ]

  alias Eblox.Data.Taxonomy

  def post_id(id), do: "#{@content_dir}/#{id}"

  test "taxonomy with comments" do
    # TODO: A few problems here:
    # - It's slow for tests.
    # - There should be a better way to wait until all posts are parsed.
    # - It may be better to setup it once per test module with `setup_all`.
    Process.sleep(10000)

    Taxonomy.add(@taxonomy, post_id("post-1"))
    Taxonomy.add(@taxonomy, post_id("post-2"))
    Taxonomy.add(@taxonomy, post_id("comment-1-1"))
    Taxonomy.add(@taxonomy, post_id("comment-1-2"))
    Taxonomy.add(@taxonomy, post_id("comment-1-2-1"))

    assert [post_id("post-1")] == Taxonomy.lookup(@taxonomy, post_id("post-1"))

    Taxonomy.remove(@taxonomy, post_id("comment-1-1"))

    assert [] == Taxonomy.lookup(@taxonomy, post_id("comment-1-1"))
  end
end
