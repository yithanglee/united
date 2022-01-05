defmodule United.Settings.Shop do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shops" do
    field :address, :string
    field :description, :binary
    field :email, :string
    field :img_url, :string
    field :name, :string
    field :phone, :string

    timestamps()
  end

  @doc false
  def changeset(shop, attrs) do
    shop
    |> cast(attrs, [:address, :description, :email, :img_url, :name, :phone])

    # |> validate_required([:address, :description, :email, :img_url, :name, :phone])
  end
end
