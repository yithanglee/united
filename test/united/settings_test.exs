defmodule United.SettingsTest do
  use United.DataCase

  alias United.Settings

  describe "users" do
    alias United.Settings.User

    @valid_attrs %{
      bio: "some bio",
      crypted_password: "some crypted_password",
      email: "some email",
      full_name: "some full_name",
      name: "some name",
      password: "some password",
      phone: "some phone"
    }
    @update_attrs %{
      bio: "some updated bio",
      crypted_password: "some updated crypted_password",
      email: "some updated email",
      full_name: "some updated full_name",
      name: "some updated name",
      password: "some updated password",
      phone: "some updated phone"
    }
    @invalid_attrs %{
      bio: nil,
      crypted_password: nil,
      email: nil,
      full_name: nil,
      name: nil,
      password: nil,
      phone: nil
    }

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Settings.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Settings.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Settings.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Settings.create_user(@valid_attrs)
      assert user.bio == "some bio"
      assert user.crypted_password == "some crypted_password"
      assert user.email == "some email"
      assert user.full_name == "some full_name"
      assert user.name == "some name"
      assert user.password == "some password"
      assert user.phone == "some phone"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Settings.update_user(user, @update_attrs)
      assert user.bio == "some updated bio"
      assert user.crypted_password == "some updated crypted_password"
      assert user.email == "some updated email"
      assert user.full_name == "some updated full_name"
      assert user.name == "some updated name"
      assert user.password == "some updated password"
      assert user.phone == "some updated phone"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_user(user, @invalid_attrs)
      assert user == Settings.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Settings.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Settings.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Settings.change_user(user)
    end
  end
end
