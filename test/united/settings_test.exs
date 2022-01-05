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

  describe "shops" do
    alias United.Settings.Shop

    @valid_attrs %{address: "some address", description: "some description", email: "some email", img_url: "some img_url", name: "some name", phone: "some phone"}
    @update_attrs %{address: "some updated address", description: "some updated description", email: "some updated email", img_url: "some updated img_url", name: "some updated name", phone: "some updated phone"}
    @invalid_attrs %{address: nil, description: nil, email: nil, img_url: nil, name: nil, phone: nil}

    def shop_fixture(attrs \\ %{}) do
      {:ok, shop} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Settings.create_shop()

      shop
    end

    test "list_shops/0 returns all shops" do
      shop = shop_fixture()
      assert Settings.list_shops() == [shop]
    end

    test "get_shop!/1 returns the shop with given id" do
      shop = shop_fixture()
      assert Settings.get_shop!(shop.id) == shop
    end

    test "create_shop/1 with valid data creates a shop" do
      assert {:ok, %Shop{} = shop} = Settings.create_shop(@valid_attrs)
      assert shop.address == "some address"
      assert shop.description == "some description"
      assert shop.email == "some email"
      assert shop.img_url == "some img_url"
      assert shop.name == "some name"
      assert shop.phone == "some phone"
    end

    test "create_shop/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_shop(@invalid_attrs)
    end

    test "update_shop/2 with valid data updates the shop" do
      shop = shop_fixture()
      assert {:ok, %Shop{} = shop} = Settings.update_shop(shop, @update_attrs)
      assert shop.address == "some updated address"
      assert shop.description == "some updated description"
      assert shop.email == "some updated email"
      assert shop.img_url == "some updated img_url"
      assert shop.name == "some updated name"
      assert shop.phone == "some updated phone"
    end

    test "update_shop/2 with invalid data returns error changeset" do
      shop = shop_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_shop(shop, @invalid_attrs)
      assert shop == Settings.get_shop!(shop.id)
    end

    test "delete_shop/1 deletes the shop" do
      shop = shop_fixture()
      assert {:ok, %Shop{}} = Settings.delete_shop(shop)
      assert_raise Ecto.NoResultsError, fn -> Settings.get_shop!(shop.id) end
    end

    test "change_shop/1 returns a shop changeset" do
      shop = shop_fixture()
      assert %Ecto.Changeset{} = Settings.change_shop(shop)
    end
  end

  describe "shop_products" do
    alias United.Settings.ShopProduct

    @valid_attrs %{cost_price: 120.5, long_desc: "some long_desc", name: "some name", promo_price: 120.5, retail_price: 120.5, shop_id: 42, short_desc: "some short_desc"}
    @update_attrs %{cost_price: 456.7, long_desc: "some updated long_desc", name: "some updated name", promo_price: 456.7, retail_price: 456.7, shop_id: 43, short_desc: "some updated short_desc"}
    @invalid_attrs %{cost_price: nil, long_desc: nil, name: nil, promo_price: nil, retail_price: nil, shop_id: nil, short_desc: nil}

    def shop_product_fixture(attrs \\ %{}) do
      {:ok, shop_product} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Settings.create_shop_product()

      shop_product
    end

    test "list_shop_products/0 returns all shop_products" do
      shop_product = shop_product_fixture()
      assert Settings.list_shop_products() == [shop_product]
    end

    test "get_shop_product!/1 returns the shop_product with given id" do
      shop_product = shop_product_fixture()
      assert Settings.get_shop_product!(shop_product.id) == shop_product
    end

    test "create_shop_product/1 with valid data creates a shop_product" do
      assert {:ok, %ShopProduct{} = shop_product} = Settings.create_shop_product(@valid_attrs)
      assert shop_product.cost_price == 120.5
      assert shop_product.long_desc == "some long_desc"
      assert shop_product.name == "some name"
      assert shop_product.promo_price == 120.5
      assert shop_product.retail_price == 120.5
      assert shop_product.shop_id == 42
      assert shop_product.short_desc == "some short_desc"
    end

    test "create_shop_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_shop_product(@invalid_attrs)
    end

    test "update_shop_product/2 with valid data updates the shop_product" do
      shop_product = shop_product_fixture()
      assert {:ok, %ShopProduct{} = shop_product} = Settings.update_shop_product(shop_product, @update_attrs)
      assert shop_product.cost_price == 456.7
      assert shop_product.long_desc == "some updated long_desc"
      assert shop_product.name == "some updated name"
      assert shop_product.promo_price == 456.7
      assert shop_product.retail_price == 456.7
      assert shop_product.shop_id == 43
      assert shop_product.short_desc == "some updated short_desc"
    end

    test "update_shop_product/2 with invalid data returns error changeset" do
      shop_product = shop_product_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_shop_product(shop_product, @invalid_attrs)
      assert shop_product == Settings.get_shop_product!(shop_product.id)
    end

    test "delete_shop_product/1 deletes the shop_product" do
      shop_product = shop_product_fixture()
      assert {:ok, %ShopProduct{}} = Settings.delete_shop_product(shop_product)
      assert_raise Ecto.NoResultsError, fn -> Settings.get_shop_product!(shop_product.id) end
    end

    test "change_shop_product/1 returns a shop_product changeset" do
      shop_product = shop_product_fixture()
      assert %Ecto.Changeset{} = Settings.change_shop_product(shop_product)
    end
  end

  describe "tags" do
    alias United.Settings.Tag

    @valid_attrs %{desc: "some desc", name: "some name"}
    @update_attrs %{desc: "some updated desc", name: "some updated name"}
    @invalid_attrs %{desc: nil, name: nil}

    def tag_fixture(attrs \\ %{}) do
      {:ok, tag} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Settings.create_tag()

      tag
    end

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Settings.list_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Settings.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Settings.create_tag(@valid_attrs)
      assert tag.desc == "some desc"
      assert tag.name == "some name"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{} = tag} = Settings.update_tag(tag, @update_attrs)
      assert tag.desc == "some updated desc"
      assert tag.name == "some updated name"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_tag(tag, @invalid_attrs)
      assert tag == Settings.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Settings.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Settings.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Settings.change_tag(tag)
    end
  end

  describe "shop_product_tags" do
    alias United.Settings.ShopProductTag

    @valid_attrs %{shop_product_id: 42, tag_id: 42}
    @update_attrs %{shop_product_id: 43, tag_id: 43}
    @invalid_attrs %{shop_product_id: nil, tag_id: nil}

    def shop_product_tag_fixture(attrs \\ %{}) do
      {:ok, shop_product_tag} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Settings.create_shop_product_tag()

      shop_product_tag
    end

    test "list_shop_product_tags/0 returns all shop_product_tags" do
      shop_product_tag = shop_product_tag_fixture()
      assert Settings.list_shop_product_tags() == [shop_product_tag]
    end

    test "get_shop_product_tag!/1 returns the shop_product_tag with given id" do
      shop_product_tag = shop_product_tag_fixture()
      assert Settings.get_shop_product_tag!(shop_product_tag.id) == shop_product_tag
    end

    test "create_shop_product_tag/1 with valid data creates a shop_product_tag" do
      assert {:ok, %ShopProductTag{} = shop_product_tag} = Settings.create_shop_product_tag(@valid_attrs)
      assert shop_product_tag.shop_product_id == 42
      assert shop_product_tag.tag_id == 42
    end

    test "create_shop_product_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_shop_product_tag(@invalid_attrs)
    end

    test "update_shop_product_tag/2 with valid data updates the shop_product_tag" do
      shop_product_tag = shop_product_tag_fixture()
      assert {:ok, %ShopProductTag{} = shop_product_tag} = Settings.update_shop_product_tag(shop_product_tag, @update_attrs)
      assert shop_product_tag.shop_product_id == 43
      assert shop_product_tag.tag_id == 43
    end

    test "update_shop_product_tag/2 with invalid data returns error changeset" do
      shop_product_tag = shop_product_tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_shop_product_tag(shop_product_tag, @invalid_attrs)
      assert shop_product_tag == Settings.get_shop_product_tag!(shop_product_tag.id)
    end

    test "delete_shop_product_tag/1 deletes the shop_product_tag" do
      shop_product_tag = shop_product_tag_fixture()
      assert {:ok, %ShopProductTag{}} = Settings.delete_shop_product_tag(shop_product_tag)
      assert_raise Ecto.NoResultsError, fn -> Settings.get_shop_product_tag!(shop_product_tag.id) end
    end

    test "change_shop_product_tag/1 returns a shop_product_tag changeset" do
      shop_product_tag = shop_product_tag_fixture()
      assert %Ecto.Changeset{} = Settings.change_shop_product_tag(shop_product_tag)
    end
  end
end
