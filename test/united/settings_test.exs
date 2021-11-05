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

  describe "blogs" do
    alias United.Settings.Blog

    @valid_attrs %{
      author: "some author",
      body: "some body",
      excerpt: "some excerpt",
      title: "some title"
    }
    @update_attrs %{
      author: "some updated author",
      body: "some updated body",
      excerpt: "some updated excerpt",
      title: "some updated title"
    }
    @invalid_attrs %{author: nil, body: nil, excerpt: nil, title: nil}

    def blog_fixture(attrs \\ %{}) do
      {:ok, blog} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Settings.create_blog()

      blog
    end

    test "list_blogs/0 returns all blogs" do
      blog = blog_fixture()
      assert Settings.list_blogs() == [blog]
    end

    test "get_blog!/1 returns the blog with given id" do
      blog = blog_fixture()
      assert Settings.get_blog!(blog.id) == blog
    end

    test "create_blog/1 with valid data creates a blog" do
      assert {:ok, %Blog{} = blog} = Settings.create_blog(@valid_attrs)
      assert blog.author == "some author"
      assert blog.body == "some body"
      assert blog.excerpt == "some excerpt"
      assert blog.title == "some title"
    end

    test "create_blog/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_blog(@invalid_attrs)
    end

    test "update_blog/2 with valid data updates the blog" do
      blog = blog_fixture()
      assert {:ok, %Blog{} = blog} = Settings.update_blog(blog, @update_attrs)
      assert blog.author == "some updated author"
      assert blog.body == "some updated body"
      assert blog.excerpt == "some updated excerpt"
      assert blog.title == "some updated title"
    end

    test "update_blog/2 with invalid data returns error changeset" do
      blog = blog_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_blog(blog, @invalid_attrs)
      assert blog == Settings.get_blog!(blog.id)
    end

    test "delete_blog/1 deletes the blog" do
      blog = blog_fixture()
      assert {:ok, %Blog{}} = Settings.delete_blog(blog)
      assert_raise Ecto.NoResultsError, fn -> Settings.get_blog!(blog.id) end
    end

    test "change_blog/1 returns a blog changeset" do
      blog = blog_fixture()
      assert %Ecto.Changeset{} = Settings.change_blog(blog)
    end
  end

  describe "stored_medias" do
    alias United.Settings.StoredMedia

    @valid_attrs %{
      f_extension: "some f_extension",
      f_type: "some f_type",
      name: "some name",
      s3_url: "some s3_url",
      size: 42
    }
    @update_attrs %{
      f_extension: "some updated f_extension",
      f_type: "some updated f_type",
      name: "some updated name",
      s3_url: "some updated s3_url",
      size: 43
    }
    @invalid_attrs %{f_extension: nil, f_type: nil, name: nil, s3_url: nil, size: nil}

    def stored_media_fixture(attrs \\ %{}) do
      {:ok, stored_media} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Settings.create_stored_media()

      stored_media
    end

    test "list_stored_medias/0 returns all stored_medias" do
      stored_media = stored_media_fixture()
      assert Settings.list_stored_medias() == [stored_media]
    end

    test "get_stored_media!/1 returns the stored_media with given id" do
      stored_media = stored_media_fixture()
      assert Settings.get_stored_media!(stored_media.id) == stored_media
    end

    test "create_stored_media/1 with valid data creates a stored_media" do
      assert {:ok, %StoredMedia{} = stored_media} = Settings.create_stored_media(@valid_attrs)
      assert stored_media.f_extension == "some f_extension"
      assert stored_media.f_type == "some f_type"
      assert stored_media.name == "some name"
      assert stored_media.s3_url == "some s3_url"
      assert stored_media.size == 42
    end

    test "create_stored_media/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_stored_media(@invalid_attrs)
    end

    test "update_stored_media/2 with valid data updates the stored_media" do
      stored_media = stored_media_fixture()

      assert {:ok, %StoredMedia{} = stored_media} =
               Settings.update_stored_media(stored_media, @update_attrs)

      assert stored_media.f_extension == "some updated f_extension"
      assert stored_media.f_type == "some updated f_type"
      assert stored_media.name == "some updated name"
      assert stored_media.s3_url == "some updated s3_url"
      assert stored_media.size == 43
    end

    test "update_stored_media/2 with invalid data returns error changeset" do
      stored_media = stored_media_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Settings.update_stored_media(stored_media, @invalid_attrs)

      assert stored_media == Settings.get_stored_media!(stored_media.id)
    end

    test "delete_stored_media/1 deletes the stored_media" do
      stored_media = stored_media_fixture()
      assert {:ok, %StoredMedia{}} = Settings.delete_stored_media(stored_media)
      assert_raise Ecto.NoResultsError, fn -> Settings.get_stored_media!(stored_media.id) end
    end

    test "change_stored_media/1 returns a stored_media changeset" do
      stored_media = stored_media_fixture()
      assert %Ecto.Changeset{} = Settings.change_stored_media(stored_media)
    end
  end
end
