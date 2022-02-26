defmodule United.Settings.FacebookPage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "facebook_pages" do
    field :name, :string
    field :page_access_token, :string
    field :page_id, :string
    field :shop_id, :integer
    field :user_id, :integer

    timestamps()
  end

  @doc false
  def changeset(facebook_page, attrs) do
    facebook_page
    |> cast(attrs, [:user_id, :name, :page_id, :page_access_token, :shop_id])
    |> validate_required([
      :user_id,
      :name,
      :page_id,
      :page_access_token
      # :shop_id
    ])
  end
end
