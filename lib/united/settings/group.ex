defmodule United.Settings.Group do
  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field :extension_period, :integer
    field :loan_limit, :integer
    field :loan_period, :integer
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :loan_limit, :loan_period, :extension_period])
    |> validate_required([:name, :loan_limit, :loan_period, :extension_period])
  end
end
