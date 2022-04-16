defmodule United.Settings.BookUpload do
  use Ecto.Schema
  import Ecto.Changeset

  schema "book_uploads" do
    field :failed_lines, :binary
    field :uploaded_by, :integer
    field :failed_qty, :integer
    field :uploaded_qty, :integer
    has_many(:book_inventories, United.Settings.BookInventory)
    timestamps()
  end

  @doc false
  def changeset(book_upload, attrs) do
    book_upload
    |> cast(attrs, [:uploaded_by, :failed_qty, :failed_lines, :uploaded_qty])

    # |> validate_required([:failed_lines])
  end
end
