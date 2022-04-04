defmodule United.Settings.BookImage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "book_images" do
    field :book_id, :integer
    field :group, :string
    field :img_url, :string

    timestamps()
  end

  @doc false
  def changeset(book_image, attrs) do
    book_image
    |> cast(attrs, [:book_id, :img_url, :group])
    |> validate_required([:book_id, :img_url, :group])
  end
end
