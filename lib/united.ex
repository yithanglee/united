defmodule United do
  @moduledoc """
  United keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

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

  def s3_large_upload(filename \\ "realized_when_lost.mp4") do
    opts = [acl: :public_read]

    res =
      "priv/static/images/#{filename}"
      |> ExAws.S3.Upload.stream_file()
      |> ExAws.S3.upload("cac-bucket", filename, opts)
      |> ExAws.request!()

    data = res.body |> SweetXml.parse()
    data |> Tuple.to_list()
  end
end
