defmodule United.Settings.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :bio, :binary
    field :crypted_password, :binary
    field :email, :string
    field :full_name, :string
    field :username, :string
    field :password, :string
    field :phone, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :full_name, :bio, :email, :phone, :password, :crypted_password])

    # |> validate_required([:username, :full_name, :bio, :email, :phone, :password, :crypted_password])
  end
end
