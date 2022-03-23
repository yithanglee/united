defmodule United.Settings do
  @moduledoc """
  The Settings context.
  """

  import Ecto.Query, warn: false
  alias United.Repo

  alias United.Settings.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_fb_user_id(id) do
    Repo.get_by(User, fb_user_id: id) |> Repo.preload(:facebook_pages)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  alias United.Settings.Blog

  @doc """
  Returns the list of blogs.

  ## Examples

      iex> list_blogs()
      [%Blog{}, ...]

  """
  def list_blogs do
    Repo.all(Blog)
  end

  def list_recent_blogs() do
    Repo.all(from b in Blog, limit: 20, order_by: [desc: b.id])
  end

  @doc """
  Gets a single blog.

  Raises `Ecto.NoResultsError` if the Blog does not exist.

  ## Examples

      iex> get_blog!(123)
      %Blog{}

      iex> get_blog!(456)
      ** (Ecto.NoResultsError)

  """
  def get_blog!(id), do: Repo.get!(Blog, id)

  @doc """
  Creates a blog.

  ## Examples

      iex> create_blog(%{field: value})
      {:ok, %Blog{}}

      iex> create_blog(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_blog(attrs \\ %{}) do
    %Blog{}
    |> Blog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a blog.

  ## Examples

      iex> update_blog(blog, %{field: new_value})
      {:ok, %Blog{}}

      iex> update_blog(blog, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_blog(%Blog{} = blog, attrs) do
    blog
    |> Blog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a blog.

  ## Examples

      iex> delete_blog(blog)
      {:ok, %Blog{}}

      iex> delete_blog(blog)
      {:error, %Ecto.Changeset{}}

  """
  def delete_blog(%Blog{} = blog) do
    Repo.delete(blog)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking blog changes.

  ## Examples

      iex> change_blog(blog)
      %Ecto.Changeset{data: %Blog{}}

  """
  def change_blog(%Blog{} = blog, attrs \\ %{}) do
    Blog.changeset(blog, attrs)
  end

  alias United.Settings.StoredMedia

  @doc """
  Returns the list of stored_medias.

  ## Examples

      iex> list_stored_medias()
      [%StoredMedia{}, ...]

  """
  def list_stored_medias do
    Repo.all(StoredMedia)
  end

  @doc """
  Gets a single stored_media.

  Raises `Ecto.NoResultsError` if the Stored media does not exist.

  ## Examples

      iex> get_stored_media!(123)
      %StoredMedia{}

      iex> get_stored_media!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stored_media!(id), do: Repo.get!(StoredMedia, id)

  @doc """
  Creates a stored_media.

  ## Examples

      iex> create_stored_media(%{field: value})
      {:ok, %StoredMedia{}}

      iex> create_stored_media(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stored_media(attrs \\ %{}) do
    a =
      %StoredMedia{}
      |> StoredMedia.changeset(attrs)
      |> Repo.insert()

    case a do
      {:ok, sm} ->
        filename = sm.s3_url |> String.replace("/images/uploads/", "")
        Task.start_link(United, :s3_large_upload, [filename])

        StoredMedia.changeset(sm, %{
          s3_url: "https://damien-bucket.ap-south-1.linodeobjects.com/#{filename}"
        })
        |> Repo.update()

        # goto s3
        nil

      _ ->
        nil
    end

    a
  end

  @doc """
  Updates a stored_media.

  ## Examples

      iex> update_stored_media(stored_media, %{field: new_value})
      {:ok, %StoredMedia{}}

      iex> update_stored_media(stored_media, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stored_media(%StoredMedia{} = stored_media, attrs) do
    stored_media
    |> StoredMedia.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stored_media.

  ## Examples

      iex> delete_stored_media(stored_media)
      {:ok, %StoredMedia{}}

      iex> delete_stored_media(stored_media)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stored_media(%StoredMedia{} = stored_media) do
    Repo.delete(stored_media)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stored_media changes.

  ## Examples

      iex> change_stored_media(stored_media)
      %Ecto.Changeset{data: %StoredMedia{}}

  """
  def change_stored_media(%StoredMedia{} = stored_media, attrs \\ %{}) do
    StoredMedia.changeset(stored_media, attrs)
  end

  alias United.Settings.Shop

  @doc """
  Returns the list of shops.

  ## Examples

      iex> list_shops()
      [%Shop{}, ...]

  """
  def list_shops do
    Repo.all(Shop)
  end

  @doc """
  Gets a single shop.

  Raises `Ecto.NoResultsError` if the Shop does not exist.

  ## Examples

      iex> get_shop!(123)
      %Shop{}

      iex> get_shop!(456)
      ** (Ecto.NoResultsError)

  """
  def get_shop!(id), do: Repo.get!(Shop, id)

  @doc """
  Creates a shop.

  ## Examples

      iex> create_shop(%{field: value})
      {:ok, %Shop{}}

      iex> create_shop(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_shop(attrs \\ %{}) do
    %Shop{}
    |> Shop.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a shop.

  ## Examples

      iex> update_shop(shop, %{field: new_value})
      {:ok, %Shop{}}

      iex> update_shop(shop, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_shop(%Shop{} = shop, attrs) do
    shop
    |> Shop.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a shop.

  ## Examples

      iex> delete_shop(shop)
      {:ok, %Shop{}}

      iex> delete_shop(shop)
      {:error, %Ecto.Changeset{}}

  """
  def delete_shop(%Shop{} = shop) do
    Repo.delete(shop)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking shop changes.

  ## Examples

      iex> change_shop(shop)
      %Ecto.Changeset{data: %Shop{}}

  """
  def change_shop(%Shop{} = shop, attrs \\ %{}) do
    Shop.changeset(shop, attrs)
  end

  alias United.Settings.ShopProduct

  @doc """
  Returns the list of shop_products.

  ## Examples

      iex> list_shop_products()
      [%ShopProduct{}, ...]

  """
  def list_shop_products do
    Repo.all(ShopProduct)
  end

  @doc """
  Gets a single shop_product.

  Raises `Ecto.NoResultsError` if the Shop product does not exist.

  ## Examples

      iex> get_shop_product!(123)
      %ShopProduct{}

      iex> get_shop_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_shop_product!(id), do: Repo.get!(ShopProduct, id)

  @doc """
  Creates a shop_product.

  ## Examples

      iex> create_shop_product(%{field: value})
      {:ok, %ShopProduct{}}

      iex> create_shop_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_shop_product(attrs \\ %{}) do
    %ShopProduct{}
    |> ShopProduct.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a shop_product.

  ## Examples

      iex> update_shop_product(shop_product, %{field: new_value})
      {:ok, %ShopProduct{}}

      iex> update_shop_product(shop_product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_shop_product(%ShopProduct{} = shop_product, attrs) do
    shop_product
    |> ShopProduct.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a shop_product.

  ## Examples

      iex> delete_shop_product(shop_product)
      {:ok, %ShopProduct{}}

      iex> delete_shop_product(shop_product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_shop_product(%ShopProduct{} = shop_product) do
    Repo.delete(shop_product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking shop_product changes.

  ## Examples

      iex> change_shop_product(shop_product)
      %Ecto.Changeset{data: %ShopProduct{}}

  """
  def change_shop_product(%ShopProduct{} = shop_product, attrs \\ %{}) do
    ShopProduct.changeset(shop_product, attrs)
  end

  alias United.Settings.Tag

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags()
      [%Tag{}, ...]

  """
  def list_tags do
    Repo.all(Tag)
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123)
      %Tag{}

      iex> get_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  alias United.Settings.ShopProductTag

  @doc """
  Returns the list of shop_product_tags.

  ## Examples

      iex> list_shop_product_tags()
      [%ShopProductTag{}, ...]

  """
  def list_shop_product_tags do
    Repo.all(ShopProductTag)
  end

  @doc """
  Gets a single shop_product_tag.

  Raises `Ecto.NoResultsError` if the Shop product tag does not exist.

  ## Examples

      iex> get_shop_product_tag!(123)
      %ShopProductTag{}

      iex> get_shop_product_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_shop_product_tag!(id), do: Repo.get!(ShopProductTag, id)

  @doc """
  Creates a shop_product_tag.

  ## Examples

      iex> create_shop_product_tag(%{field: value})
      {:ok, %ShopProductTag{}}

      iex> create_shop_product_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_shop_product_tag(attrs \\ %{}) do
    %ShopProductTag{}
    |> ShopProductTag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a shop_product_tag.

  ## Examples

      iex> update_shop_product_tag(shop_product_tag, %{field: new_value})
      {:ok, %ShopProductTag{}}

      iex> update_shop_product_tag(shop_product_tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_shop_product_tag(%ShopProductTag{} = shop_product_tag, attrs) do
    shop_product_tag
    |> ShopProductTag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a shop_product_tag.

  ## Examples

      iex> delete_shop_product_tag(shop_product_tag)
      {:ok, %ShopProductTag{}}

      iex> delete_shop_product_tag(shop_product_tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_shop_product_tag(%ShopProductTag{} = shop_product_tag) do
    Repo.delete(shop_product_tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking shop_product_tag changes.

  ## Examples

      iex> change_shop_product_tag(shop_product_tag)
      %Ecto.Changeset{data: %ShopProductTag{}}

  """
  def change_shop_product_tag(%ShopProductTag{} = shop_product_tag, attrs \\ %{}) do
    ShopProductTag.changeset(shop_product_tag, attrs)
  end

  alias United.Settings.FacebookPage

  @doc """
  Returns the list of facebook_pages.

  ## Examples

      iex> list_facebook_pages()
      [%FacebookPage{}, ...]

  """
  def list_facebook_pages do
    Repo.all(FacebookPage)
  end

  @doc """
  Gets a single facebook_page.

  Raises `Ecto.NoResultsError` if the Facebook page does not exist.

  ## Examples

      iex> get_facebook_page!(123)
      %FacebookPage{}

      iex> get_facebook_page!(456)
      ** (Ecto.NoResultsError)

  """
  def get_facebook_page!(id), do: Repo.get!(FacebookPage, id)

  def get_facebook_page_by_pat(page_access_token) do
    Repo.all(
      from p in FacebookPage,
        where: p.page_access_token == ^page_access_token,
        preload: [:live_videos]
    )
  end

  @doc """
  Creates a facebook_page.

  ## Examples

      iex> create_facebook_page(%{field: value})
      {:ok, %FacebookPage{}}

      iex> create_facebook_page(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_facebook_page(attrs \\ %{}) do
    %FacebookPage{}
    |> FacebookPage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a facebook_page.

  ## Examples

      iex> update_facebook_page(facebook_page, %{field: new_value})
      {:ok, %FacebookPage{}}

      iex> update_facebook_page(facebook_page, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_facebook_page(%FacebookPage{} = facebook_page, attrs) do
    facebook_page
    |> FacebookPage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a facebook_page.

  ## Examples

      iex> delete_facebook_page(facebook_page)
      {:ok, %FacebookPage{}}

      iex> delete_facebook_page(facebook_page)
      {:error, %Ecto.Changeset{}}

  """
  def delete_facebook_page(%FacebookPage{} = facebook_page) do
    Repo.delete(facebook_page)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking facebook_page changes.

  ## Examples

      iex> change_facebook_page(facebook_page)
      %Ecto.Changeset{data: %FacebookPage{}}

  """
  def change_facebook_page(%FacebookPage{} = facebook_page, attrs \\ %{}) do
    FacebookPage.changeset(facebook_page, attrs)
  end

  alias United.Settings.LiveVideo

  @doc """
  Returns the list of live_videos.

  ## Examples

      iex> list_live_videos()
      [%LiveVideo{}, ...]

  """
  def list_live_videos do
    Repo.all(LiveVideo)
  end

  @doc """
  Gets a single live_video.

  Raises `Ecto.NoResultsError` if the Live video does not exist.

  ## Examples

      iex> get_live_video!(123)
      %LiveVideo{}

      iex> get_live_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_live_video!(id), do: Repo.get!(LiveVideo, id) |> Repo.preload(:facebook_page)

  def get_live_video_by_fb_id(id) do
    Repo.all(from lv in LiveVideo, where: lv.live_id == ^id) |> List.first()
  end

  @doc """
  Creates a live_video.

  ## Examples

      iex> create_live_video(%{field: value})
      {:ok, %LiveVideo{}}

      iex> create_live_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_live_video(attrs \\ %{}) do
    %LiveVideo{}
    |> LiveVideo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a live_video.

  ## Examples

      iex> update_live_video(live_video, %{field: new_value})
      {:ok, %LiveVideo{}}

      iex> update_live_video(live_video, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_live_video(%LiveVideo{} = live_video, attrs) do
    live_video
    |> LiveVideo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a live_video.

  ## Examples

      iex> delete_live_video(live_video)
      {:ok, %LiveVideo{}}

      iex> delete_live_video(live_video)
      {:error, %Ecto.Changeset{}}

  """
  def delete_live_video(%LiveVideo{} = live_video) do
    Repo.delete(live_video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking live_video changes.

  ## Examples

      iex> change_live_video(live_video)
      %Ecto.Changeset{data: %LiveVideo{}}

  """
  def change_live_video(%LiveVideo{} = live_video, attrs \\ %{}) do
    LiveVideo.changeset(live_video, attrs)
  end

  alias United.Settings.VideoComment

  @doc """
  Returns the list of video_comments.

  ## Examples

      iex> list_video_comments()
      [%VideoComment{}, ...]

  """
  def list_video_comments do
    Repo.all(VideoComment)
  end

  @doc """
  Gets a single video_comment.

  Raises `Ecto.NoResultsError` if the Video comment does not exist.

  ## Examples

      iex> get_video_comment!(123)
      %VideoComment{}

      iex> get_video_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_video_comment!(id), do: Repo.get!(VideoComment, id)

  @doc """
  Creates a video_comment.

  ## Examples

      iex> create_video_comment(%{field: value})
      {:ok, %VideoComment{}}

      iex> create_video_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_video_comment(attrs \\ %{}) do
    pid =
      with pid <- Process.whereis(:comments),
           true <- pid != nil do
        pid
      else
        _ ->
          {:ok, pid} = Agent.start_link(fn -> [] end)
          Process.register(pid, :comments)
          pid
      end

    check =
      Agent.get(pid, fn list -> list end)
      |> Enum.reject(&(&1 == nil))
      |> Enum.filter(&(&1.ms_id == attrs.ms_id))

    pv =
      if check == [] do
        res = Repo.all(from p in VideoComment, where: p.ms_id == ^attrs.ms_id) |> List.first()

        f =
          if res == nil do
            %VideoComment{}
            |> VideoComment.changeset(attrs)
            |> Repo.insert!()
          else
            res
          end

        Agent.update(pid, fn list -> List.insert_at(list, 0, res) end)

        f
      else
        List.first(check)
      end
  end

  @doc """
  Updates a video_comment.

  ## Examples

      iex> update_video_comment(video_comment, %{field: new_value})
      {:ok, %VideoComment{}}

      iex> update_video_comment(video_comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_video_comment(%VideoComment{} = video_comment, attrs) do
    video_comment
    |> VideoComment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a video_comment.

  ## Examples

      iex> delete_video_comment(video_comment)
      {:ok, %VideoComment{}}

      iex> delete_video_comment(video_comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_video_comment(%VideoComment{} = video_comment) do
    Repo.delete(video_comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking video_comment changes.

  ## Examples

      iex> change_video_comment(video_comment)
      %Ecto.Changeset{data: %VideoComment{}}

  """
  def change_video_comment(%VideoComment{} = video_comment, attrs \\ %{}) do
    VideoComment.changeset(video_comment, attrs)
  end

  alias United.Settings.PageVisitor

  @doc """
  Returns the list of page_visitors.

  ## Examples

      iex> list_page_visitors()
      [%PageVisitor{}, ...]

  """
  def list_page_visitors do
    Repo.all(PageVisitor)
  end

  @doc """
  Gets a single page_visitor.

  Raises `Ecto.NoResultsError` if the Page visitor does not exist.

  ## Examples

      iex> get_page_visitor!(123)
      %PageVisitor{}

      iex> get_page_visitor!(456)
      ** (Ecto.NoResultsError)

  """
  def get_page_visitor!(id), do: Repo.get!(PageVisitor, id)

  def get_page_visitor_by_psid(psid) do
    pid =
      with pid <- Process.whereis(:page_visitors),
           true <- pid != nil do
        pid
      else
        _ ->
          {:ok, pid} = Agent.start_link(fn -> [] end)
          Process.register(pid, :page_visitors)
          pid
      end

    check = Agent.get(pid, fn list -> list end) |> Enum.filter(&(&1.psid == psid))

    pv =
      if check == [] do
        res = Repo.all(from p in PageVisitor, where: p.psid == ^psid) |> List.first()

        if res != nil do
          Agent.update(pid, fn list -> List.insert_at(list, 0, res) end)
        end

        res
      else
        List.first(check)
      end
  end

  @doc """
  Creates a page_visitor.

  ## Examples

      iex> create_page_visitor(%{field: value})
      {:ok, %PageVisitor{}}

      iex> create_page_visitor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_page_visitor(attrs \\ %{}) do
    %PageVisitor{}
    |> PageVisitor.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a page_visitor.

  ## Examples

      iex> update_page_visitor(page_visitor, %{field: new_value})
      {:ok, %PageVisitor{}}

      iex> update_page_visitor(page_visitor, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_page_visitor(%PageVisitor{} = page_visitor, attrs) do
    page_visitor
    |> PageVisitor.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a page_visitor.

  ## Examples

      iex> delete_page_visitor(page_visitor)
      {:ok, %PageVisitor{}}

      iex> delete_page_visitor(page_visitor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_page_visitor(%PageVisitor{} = page_visitor) do
    Repo.delete(page_visitor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking page_visitor changes.

  ## Examples

      iex> change_page_visitor(page_visitor)
      %Ecto.Changeset{data: %PageVisitor{}}

  """
  def change_page_visitor(%PageVisitor{} = page_visitor, attrs \\ %{}) do
    PageVisitor.changeset(page_visitor, attrs)
  end

  alias United.Settings.CustomerOrder

  @doc """
  Returns the list of customer_orders.

  ## Examples

      iex> list_customer_orders()
      [%CustomerOrder{}, ...]

  """
  def list_customer_orders do
    Repo.all(CustomerOrder)
  end

  @doc """
  Gets a single customer_order.

  Raises `Ecto.NoResultsError` if the Customer order does not exist.

  ## Examples

      iex> get_customer_order!(123)
      %CustomerOrder{}

      iex> get_customer_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_customer_order!(id), do: Repo.get!(CustomerOrder, id)

  @doc """
  Creates a customer_order.

  ## Examples

      iex> create_customer_order(%{field: value})
      {:ok, %CustomerOrder{}}

      iex> create_customer_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_customer_order(attrs \\ %{}) do
    %CustomerOrder{}
    |> CustomerOrder.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a customer_order.

  ## Examples

      iex> update_customer_order(customer_order, %{field: new_value})
      {:ok, %CustomerOrder{}}

      iex> update_customer_order(customer_order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_customer_order(%CustomerOrder{} = customer_order, attrs) do
    customer_order
    |> CustomerOrder.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a customer_order.

  ## Examples

      iex> delete_customer_order(customer_order)
      {:ok, %CustomerOrder{}}

      iex> delete_customer_order(customer_order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_customer_order(%CustomerOrder{} = customer_order) do
    Repo.delete(customer_order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer_order changes.

  ## Examples

      iex> change_customer_order(customer_order)
      %Ecto.Changeset{data: %CustomerOrder{}}

  """
  def change_customer_order(%CustomerOrder{} = customer_order, attrs \\ %{}) do
    CustomerOrder.changeset(customer_order, attrs)
  end

  alias United.Settings.CustomerOrderLine

  @doc """
  Returns the list of customer_order_lines.

  ## Examples

      iex> list_customer_order_lines()
      [%CustomerOrderLine{}, ...]

  """
  def list_customer_order_lines do
    Repo.all(CustomerOrderLine)
  end

  @doc """
  Gets a single customer_order_line.

  Raises `Ecto.NoResultsError` if the Customer order line does not exist.

  ## Examples

      iex> get_customer_order_line!(123)
      %CustomerOrderLine{}

      iex> get_customer_order_line!(456)
      ** (Ecto.NoResultsError)

  """
  def get_customer_order_line!(id), do: Repo.get!(CustomerOrderLine, id)

  @doc """
  Creates a customer_order_line.

  ## Examples

      iex> create_customer_order_line(%{field: value})
      {:ok, %CustomerOrderLine{}}

      iex> create_customer_order_line(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_customer_order_line(attrs \\ %{}) do
    %CustomerOrderLine{}
    |> CustomerOrderLine.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a customer_order_line.

  ## Examples

      iex> update_customer_order_line(customer_order_line, %{field: new_value})
      {:ok, %CustomerOrderLine{}}

      iex> update_customer_order_line(customer_order_line, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_customer_order_line(%CustomerOrderLine{} = customer_order_line, attrs) do
    customer_order_line
    |> CustomerOrderLine.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a customer_order_line.

  ## Examples

      iex> delete_customer_order_line(customer_order_line)
      {:ok, %CustomerOrderLine{}}

      iex> delete_customer_order_line(customer_order_line)
      {:error, %Ecto.Changeset{}}

  """
  def delete_customer_order_line(%CustomerOrderLine{} = customer_order_line) do
    Repo.delete(customer_order_line)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer_order_line changes.

  ## Examples

      iex> change_customer_order_line(customer_order_line)
      %Ecto.Changeset{data: %CustomerOrderLine{}}

  """
  def change_customer_order_line(%CustomerOrderLine{} = customer_order_line, attrs \\ %{}) do
    CustomerOrderLine.changeset(customer_order_line, attrs)
  end

  def save_sync_items(accounting_access_token, list) do
    check =
      Repo.all(from s in Shop, where: s.accounting_accesss_token == ^accounting_access_token)

    shop =
      if check != [] do
        List.first(check)
      else
        nil
      end

    sample = %{
      "address" => nil,
      "balance" => -575,
      "base_uom_id" => nil,
      "code" => "RB",
      "default_price" => 6.2,
      "description" => "RIB",
      "id" => 1,
      "image_url" => nil,
      "inserted_at" => "2021-12-30T03:12:16",
      "lat" => nil,
      "long" => nil,
      "name" => "RIB",
      "property" => "product",
      "short_desc" => "RIB",
      "updated_at" => "2021-12-30T03:12:16"
    }

    if shop != nil do
      for a <- list do
        item = BluePotion.string_to_atom(a, Map.keys(a))
        ext_id = "mini_acc_item_id:#{item.id}"
        rcheck = Repo.all(from sp in ShopProduct, where: sp.external_id == ^ext_id)

        if rcheck == [] do
          create_shop_product(%{
            shop_id: shop.id,
            short_desc: item.short_desc,
            long_desc: item.description,
            item_code: item.code,
            retail_price: item.default_price,
            name: item.name,
            external_id: ext_id
          })
        else
          sp = List.first(rcheck)

          update_shop_product(sp, %{
            shop_id: shop.id,
            short_desc: item.short_desc,
            long_desc: item.description,
            item_code: item.code,
            retail_price: item.default_price,
            name: item.name
          })
        end
      end
    end
  end

  def update_customer_order_by_external_id(external_id, status) do
    check = Repo.all(from co in CustomerOrder, where: co.external_id == ^external_id)

    if check != [] do
      co = List.first(check) |> Repo.preload(page_visitor: :facebook_page)

      if status == :paid do
        update_customer_order(co, %{status: :paid, delivery_status: :packing})

        FacebookHelper.handlePostback(co.page_visitor.facebook_page, co.page_visitor, %{
          "payload" => "thank_you_payment:#{co.id}"
        })
      else
        update_customer_order(co, %{status: :pending_payment})

        FacebookHelper.handlePostback(co.page_visitor.facebook_page, co.page_visitor, %{
          "payload" => "failed_payment:#{co.id}"
        })
      end
    end
  end

  def get_psid_orders(page_visitor) do
    data = page_visitor |> Repo.preload(customer_orders: :customer_order_lines)

    IO.inspect(data)

    data
    |> Map.get(:customer_orders)
    |> Enum.filter(&(&1.status in [:pending_payment, :pending_confirmation]))
  end

  def finalize_order(%{"live_id" => live_id, "order" => order}) do
    live_video = Repo.get_by(LiveVideo, live_id: live_id)

    check =
      Repo.all(
        from co in CustomerOrder,
          where:
            co.live_video_id == ^live_video.id and
              co.page_visitor_id == ^order["page_visitor"]["id"]
      )

    co =
      if check == [] do
        {:ok, co} =
          create_customer_order(%{
            date: Date.utc_today(),
            live_video_id: live_video.id,
            page_visitor_id: order["page_visitor"]["id"]
          })

        co
      else
        List.first(check)
      end

    Repo.delete_all(from col in CustomerOrderLine, where: col.customer_order_id == ^co.id)
    indexes = order["items"] |> Map.keys()

    for index <- indexes do
      data = order["items"][index]

      sample = %{
        "data" => %{
          "0" => %{
            "created_at" => "2022-03-15T04:10:15",
            "id" => "587",
            "inserted_at" => "2022-03-15T04:10:19",
            "live_video_id" => "37",
            "message" => "P10",
            "ms_id" => "650653936200605_650687916197207",
            "page_visitor" => %{
              "email" => "",
              "facebook_page_id" => "",
              "id" => "2",
              "inserted_at" => "2022-02-26T16:07:17",
              "name" => "Yithang Lee",
              "phone" => "",
              "profile_pic" => "",
              "psid" => "3835391016494832",
              "updated_at" => "2022-02-26T16:07:17"
            },
            "page_visitor_id" => "2",
            "product" => %{
              "cost_price" => "",
              "external_id" => "",
              "id" => "2",
              "inserted_at" => "2022-01-05T02:05:48",
              "item_code" => "P10",
              "long_desc" => "",
              "name" => "猪肉干",
              "promo_price" => "",
              "retail_price" => "46",
              "shop_id" => "1",
              "short_desc" => "Minced Pork",
              "updated_at" => "2022-03-14T14:22:35"
            },
            "updated_at" => "2022-03-15T04:10:19"
          }
        },
        "item_code" => "P10",
        "item_name" => "猪肉干",
        "price" => "46",
        "qty" => "1"
      }

      IO.inspect(data)
      product = data["data"]
      IO.inspect(product)
      qty = data["qty"] |> Integer.parse() |> elem(0)
      cp = data["price"] |> Float.parse() |> elem(0)

      external_id =
        with true <- product["external_id"] == "",
             sp <- United.Settings.get_shop_product!(product["id"]),
             true <- sp != nil do
          sp.external_id
        else
          _ ->
            product["external_id"]
        end

      create_customer_order_line(%{
        customer_order_id: co.id,
        cost_price: cp,
        qty: qty,
        sub_total: (qty * cp) |> Float.round(2),
        remarks: "customization that refers to size and color",
        item_name: data["item_name"],
        external_id: external_id,
        shop_product_id: product["id"]
      })

      # allow user to check the details of the order
      # next here is where the messenger will ask the user to fill in the delivery address
    end
  end

  def update_co_address(
        %{
          "address" => address,
          "id" => id,
          "payment_method" => payment_method,
          "phone" => phone,
          "city" => city,
          "postcode" => postcode,
          "scope" => _scope,
          "state" => state
        } = params
      ) do
    payment_method =
      case payment_method do
        "Online Payment(FPX)" ->
          "Online Payment(FPX)"

        _ ->
          payment_method
      end

    co = get_customer_order!(id) |> Repo.preload(page_visitor: :facebook_page)

    update_customer_order(co, %{
      payment_method: payment_method,
      delivery_address: "#{address}\r\n#{city}\r\n#{postcode}\r\n#{state}",
      delivery_phone: phone
    })

    FacebookHelper.handlePostback(co.page_visitor.facebook_page, co.page_visitor, %{
      "payload" => "check_order"
    })
  end

  def generate_lines(co) do
    # co =
    #   get_customer_order!(co_id)
    #   |> Repo.preload([:customer_order_lines])

    res = co |> Map.get(:customer_order_lines) |> Enum.map(&(&1 |> BluePotion.s_to_map()))

    indexed = res |> Enum.with_index()

    for {item, index} <- indexed do
      {index,
       %{
         "item_id" => item.external_id |> String.replace("mini_acc_item_id:", ""),
         "item_name" => item.item_name,
         "line_total" => item.sub_total,
         "qty" => item.qty,
         "qty2" => item.qty,
         "remarks" => item.remarks,
         "sub_total" => item.sub_total,
         "tax" => "0.00",
         "tax_code" => "1",
         "unit_cost" => item.cost_price
       }}
    end
    |> Enum.into(%{})
  end

  def send_customer_order_to_accounting(co_id) do
    co =
      get_customer_order!(co_id)
      |> Repo.preload([:customer_order_lines, page_visitor: [facebook_page: :shop]])

    # get account id
    # get sales person id?
    {:ok, resp} =
      Accounting.request("sales_users", %{
        scope: "sales_users",
        token: co.page_visitor.facebook_page.shop.accounting_accesss_token
      })

    sales_users = resp.body |> Jason.decode!()

    {:ok, resp} =
      Accounting.request("debtor", %{
        scope: "create_debtor",
        token: co.page_visitor.facebook_page.shop.accounting_accesss_token,
        name: co.page_visitor.name,
        code: co.page_visitor.psid,
        email: "",
        tel_no: co.delivery_phone,
        address: co.delivery_address
      })

    debtor = resp.body |> Jason.decode!()

    nparams = %{
      "scope" => "create_co",
      "account_document_line" => generate_lines(co),
      "account_documents" => %{
        "account_id" => "#{debtor["id"]}",
        "created_by" => "#{List.last(sales_users)["id"]}",
        "date" => Date.utc_today(),
        "document_type" => "customer_order",
        "id" => "0"
      },
      "model" => "account_documents"
    }

    {:ok, res} =
      Accounting.post(
        Jason.encode!(nparams),
        co.page_visitor.facebook_page.shop.accounting_accesss_token
      )

    parent_acc_doc = res.body |> Jason.decode!()

    nparam2 = %{
      "scope" => "create_do",
      "account_document_line" => generate_lines(co),
      "account_documents" => %{
        "account_id" => "#{debtor["id"]}",
        "created_by" => "#{List.last(sales_users)["id"]}",
        "date" => Date.utc_today(),
        "delivery_address" => co.delivery_address,
        "delivery_date" => Date.utc_today(),
        "delivery_name" => co.page_visitor.name,
        "delivery_phone" => co.delivery_phone,
        "document_type" => "customer_delivery_order",
        "id" => "0",
        "parent_acc_doc_id" => parent_acc_doc["id"]
      },
      "model" => "account_documents"
    }

    {:ok, res} =
      Accounting.post(
        Jason.encode!(nparam2),
        co.page_visitor.facebook_page.shop.accounting_accesss_token
      )

    customer_delivery_order = res.body |> Jason.decode!()

    nparam3 = %{
      "document_type" => "customer_delivery_order",
      "id" => customer_delivery_order["id"],
      "scope" => "post_account_document"
    }

    {:ok, res3} =
      Accounting.post(
        Jason.encode!(nparam3),
        co.page_visitor.facebook_page.shop.accounting_accesss_token
      )

    invoice_object = res3.body |> Jason.decode!()

    invoice_id = invoice_object["object"]["id"]

    {:ok, co} = update_customer_order(co, %{external_id: "accounting_invoice_id:#{invoice_id}"})

    {:ok, res} =
      Accounting.get(
        "get_payment_link?invoice_id=#{invoice_id}",
        co.page_visitor.facebook_page.shop.accounting_accesss_token
      )

    {:ok, co} = update_customer_order(co, %{payment_gateway_link: res.body |> Jason.decode!()})

    FacebookHelper.handlePostback(co.page_visitor.facebook_page, co.page_visitor, %{
      "payload" => "make_payment"
    })

    IO.inspect(co)
    IO.inspect(debtor)
    IO.inspect(sales_users)
    IO.inspect(parent_acc_doc)
    IO.inspect(customer_delivery_order)
    IO.inspect(res3.body |> Jason.decode!())
    IO.inspect(res.body |> Jason.decode!())
  end
end
