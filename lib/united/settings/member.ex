defmodule United.Settings.Member do
  use Ecto.Schema
  import Ecto.Changeset

  schema "members" do
    field :address, :string
    field :city, :string
    field :code, :string
    field :email, :string
    field :fb_user_id, :string
    # field :group_id, :integer
    belongs_to(:group, United.Settings.Group)
    field :ic, :string
    field :name, :string
    field :phone, :string
    field :postcode, :string
    field :psid, :string

    timestamps()
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [
      :name,
      :address,
      :postcode,
      :city,
      :group_id,
      :fb_user_id,
      :psid,
      :phone,
      :ic,
      :email,
      :code
    ])
    |> validate_required([
      :name,
      # :address,
      # :postcode,
      # :city,
      :group_id,
      # :fb_user_id,
      # :psid,
      :phone,
      :ic,
      # :email,
      :code
    ])
  end
end
