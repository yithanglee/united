defmodule United.Settings.BookCategory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "book_categories" do
    field :chinese_name, :string
    field :code, :string
    field :description, :binary
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(book_category, attrs) do
    book_category
    |> cast(attrs, [:name, :code, :chinese_name, :description])

    # |> validate_required([:name, :code, :chinese_name, :description])
  end
end
