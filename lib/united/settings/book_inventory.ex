defmodule United.Settings.BookInventory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "book_inventories" do
    # field :book_category_id, :integer
    # field :book_id, :integer
    belongs_to(:book_category, United.Settings.BookCategory, on_replace: :update)
    belongs_to(:book, United.Settings.Book, on_replace: :update)
    has_one(:author, through: [:book, :author])
    has_one(:publisher, through: [:book, :publisher])
    field :book_upload_id, :integer
    has_many(:book_images, through: [:book, :book_images])
    has_many(:loans, United.Settings.Loan)
    field :code, :string

    timestamps()
  end

  @doc false
  def changeset(book_inventory, attrs) do
    book_inventory
    |> cast(attrs, [:book_upload_id, :code, :book_category_id])
  end

  def update_changeset(book_inventory, attrs) do
    book_inventory
    |> cast(attrs, [:book_upload_id, :book_id, :code, :book_category_id])
  end
end
