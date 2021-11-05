defmodule United do
  @moduledoc """
  United keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def upload_file(params) do
    check_upload =
      Map.values(params)
      |> Enum.with_index()
      |> Enum.filter(fn x -> is_map(elem(x, 0)) end)
      |> Enum.filter(fn x -> :__struct__ in Map.keys(elem(x, 0)) end)
      |> Enum.filter(fn x -> elem(x, 0).__struct__ == Plug.Upload end)

    if check_upload != [] do
      file_plug = hd(check_upload) |> elem(0)
      index = hd(check_upload) |> elem(1)

      check = File.exists?(File.cwd!() <> "/media")

      path =
        if check do
          File.cwd!() <> "/media"
        else
          File.mkdir(File.cwd!() <> "/media")
          File.cwd!() <> "/media"
        end

      final =
        if is_map(file_plug) do
          IO.inspect(is_map(file_plug))
          fl = String.replace(file_plug.filename, "'", "")
          File.cp(file_plug.path, path <> "/#{fl}")
          "/images/uploads/#{fl}"
        else
          "/images/uploads/#{file_plug}"
        end

      Map.put(params, Enum.at(Map.keys(params), index), final)
    else
      params
    end
  end

  def create_new_bucket(bucket_name) do
    url = "https://api.linode.com/v4/object-storage/buckets"

    token = Application.get_env(:ex_aws, :pat)

    resp =
      HTTPoison.post(url, Poison.encode!(%{label: bucket_name, cluster: "ap-south-1"}), [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ])

    case resp do
      {:ok, res} ->
        res.body |> Poison.decode!()

      {:error, error} ->
        IO.inspect(error)
        ""
    end
  end

  def list_bucket() do
    token = Application.get_env(:ex_aws, :pat)

    # `44675ea568c8d8605fe7af0bf7ce66de28f751f25cc62b87fff970080f31b31f
    resp =
      HTTPoison.get("https://api.linode.com/v4/object-storage/buckets", [
        {"Authorization", "Bearer #{token}"}
      ])

    case resp do
      {:ok, res} ->
        res.body |> Poison.decode!()

      {:error, error} ->
        IO.inspect(error)
        ""
    end
  end

  def s3_large_upload(filename) do
    opts = [acl: :public_read]

    check = File.exists?(File.cwd!() <> "/media")

    path =
      if check do
        File.cwd!() <> "/media"
      else
        File.mkdir(File.cwd!() <> "/media")
        File.cwd!() <> "/media"
      end

    res =
      "#{path}/#{filename}"
      |> ExAws.S3.Upload.stream_file()
      |> ExAws.S3.upload("damien-bucket", filename, opts)
      |> ExAws.request!()

    data = res.body |> SweetXml.parse()
    IO.inspect(data |> Tuple.to_list())
    :ok
  end
end
