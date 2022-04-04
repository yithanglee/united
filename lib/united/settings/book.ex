defmodule United.Settings.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    # field :author_id, :integer
    # field :publisher_id, :integer
    field :description, :binary
    field :title, :string
    field :isbn, :string
    field :call_number, :string
    belongs_to(:author, United.Settings.Author, on_replace: :update)
    belongs_to(:publisher, United.Settings.Publisher, on_replace: :update)

    timestamps()
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:call_number, :isbn, :title, :description])
    |> cast_assoc(:author)
    |> cast_assoc(:publisher)
    |> validate_required([:title])
  end

  def update_changeset(book, attrs) do
    book
    |> cast(attrs, [:call_number, :isbn, :title, :author_id, :publisher_id, :description])
    |> validate_required([:title])
  end
end
