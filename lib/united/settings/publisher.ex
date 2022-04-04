defmodule United.Settings.Publisher do
  use Ecto.Schema
  import Ecto.Changeset

  schema "publishers" do
    field :bio, :binary
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(publisher, attrs) do
    publisher
    |> cast(attrs, [:name, :bio])
    |> validate_required([:name])
  end
end
