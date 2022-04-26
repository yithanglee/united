defmodule UnitedWeb.ApiController do
  use UnitedWeb, :controller
  import Mogrify

  @app_secret "2e210fa67f156f26d8d9adb2f5524b9e"
  @app_id "716495772618929"
  @page_access_token "EAAKLpiwCkLEBAJ4IXng9ZAWLL4KkwkNhySnKlqxt04slrJqnqdJtDI4hfqFtIpoqaAyP4NcpzVXBFxFr7GiZAbQ6WvM4SEZCAyIaNb5wJjOKF7cvMKjhILrNNwPv3HSoZCo5cgcAMvC1LH5b16ZAIHaBN5CK8kswr4mdcn2VZCYMEV35rhOBbE"
  import FacebookHelper
  require Logger

  def fb_webhook(conn, params) do
    # parameter = Repo.get_by(Settings.Parameter, name: "page_access_token")

    # pat = parameter.cvalue

    challenge = params["hub.challenge"]
    mode = params["hub.mode"]
    token = params["hub.verify_token"]

    if mode != nil and token != nil do
      IO.puts(mode)

      if mode == "subscribe" and token == @page_access_token do
        IO.puts("WEBHOOK_VERIFIED")
        send_resp(conn, 200, challenge)
      else
        send_resp(conn, 500, [])
      end
    else
      send_resp(conn, 500, [])
    end
  end

  require IEx

  def fb_webhook_post(conn, params) do
    IO.inspect(params)

    sample = %{
      "entry" => [
        %{
          "changes" => [
            %{
              "field" => "live_videos",
              "value" => %{"id" => "4444444444", "status" => "live_stopped"}
            }
          ],
          "id" => "0",
          "time" => 1_645_812_508
        }
      ],
      "object" => "page"
    }

    case params["object"] do
      "page" ->
        entry_list = params["entry"]

        for %{"changes" => changes} = item <- entry_list do
          cond do
            changes |> Enum.map(&(&1["field"] == "live_videos")) ->
              IO.inspect(List.first(changes)["value"])
          end
        end

        for %{"messaging" => messaging2} = item <- entry_list do
          %{
            "time" => time,
            "messaging" => messages,
            "id" => fb_page_id
          } = item

          page = United.Repo.get_by(United.Settings.FacebookPage, page_id: fb_page_id)

          if page != nil do
            set_ps = fn sender_psid ->
              page_visitor =
                United.Repo.get_by(United.Settings.PageVisitor,
                  facebook_page_id: page.id,
                  psid: sender_psid
                )

              page_visitor =
                if page_visitor == nil do
                  existing_page_commenter =
                    United.Repo.get_by(United.Settings.PageVisitor,
                      psid: sender_psid
                    )

                  {:ok, p} =
                    if existing_page_commenter == nil do
                      United.Settings.create_page_visitor(%{
                        facebook_page_id: page.id,
                        psid: sender_psid
                      })
                    else
                      United.Settings.update_page_visitor(existing_page_commenter, %{
                        facebook_page_id: page.id
                      })
                    end

                  p
                else
                  page_visitor
                end
            end

            for %{"message" => content, "sender" => %{"id" => psid}} = message <- messages do
              Logger.info("[FB MESSENGER]: Sender PSID: " <> psid)

              handleMessage(page, set_ps.(psid), content)
            end

            for %{"postback" => postback, "sender" => %{"id" => psid}} = message <- messages do
              Logger.info("[FB MESSENGER]: Sender PSID: " <> psid)

              handlePostback(page, set_ps.(psid), postback)
            end
          end
        end

        send_resp(conn, 200, "EVENT_RECEIVED")

      "user" ->
        entry_list = params["entry"]
        IO.puts(Jason.encode!(entry_list))

        for item <- entry_list do
          fb_user_id = item["uid"]

          if Enum.any?(item["changed_fields"], fn x -> x == "live_videos" end) do
            company_name = params["company_name"]

            # check_user_live_video(fb_user_id, company_name)
          end
        end

        send_resp(conn, 200, "EVENT_RECEIVED")

      _ ->
        send_resp(conn, 500, [])
    end
  end

  def webhook_post(conn, params) do
    final =
      case params["scope"] do
        "scan_image" ->
          image =
            open(params["image"].path)
            |> resize("1200x1200")
            |> save
            |> IO.inspect()

          a =
            File.read!(image.path)
            |> Base.encode64()
            |> IO.inspect()

          Elixir.Task.start_link(United, :inspect_image, [a])
          %{status: "ok"}

        "strong_search" ->
          q = params["query"]

          United.Settings.strong_search_book_inventory(q)
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        "update_member_profile" ->
          {:ok, map} = Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", params["token"])
          user = United.Settings.get_member!(map.id)
          res = United.Settings.update_member(user, BluePotion.upload_file(params["Member"]))

          case res do
            {:ok, u} ->
              %{status: "ok"}

            {:error, cg} ->
              IO.inspect(cg)
              %{status: "error"}
          end

        "update_profile" ->
          {:ok, map} = Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", params["token"])
          user = United.Settings.get_user!(map.id)
          res = United.Settings.update_user(user, BluePotion.upload_file(params["User"]))

          case res do
            {:ok, u} ->
              %{status: "ok"}

            {:error, cg} ->
              IO.inspect(cg)
              %{status: "error"}
          end

        "process_books" ->
          type = params["books"].filename |> String.split(".") |> Enum.fetch!(1)

          data =
            case type do
              "xlsx" ->
                {:ok, tid} = Xlsxir.extract(params["books"].path, 0)
                bin = Xlsxir.get_list(tid)

                header = bin |> List.first()
                body = bin |> List.delete_at(0) |> IO.inspect()

                result =
                  for content <- body do
                    h = header |> Enum.map(fn x -> String.upcase(x) |> String.trim() end)

                    content =
                      content |> Enum.map(fn x -> x end) |> Enum.filter(fn x -> x != "\"" end)

                    c =
                      for item <- content do
                        item =
                          if is_float(item) == true do
                            item |> Float.to_string()
                          else
                            item
                          end

                        item =
                          case item do
                            "@@@" ->
                              ","

                            "\\N" ->
                              ""

                            _ ->
                              item
                          end

                        a =
                          case item do
                            {:ok, i} ->
                              i

                            _ ->
                              cond do
                                item == " " ->
                                  "null"

                                item == "  " ->
                                  "null"

                                item == "   " ->
                                  "null"

                                item == nil ->
                                  "null"

                                true ->
                                  item
                              end
                          end
                      end

                    item_param =
                      Enum.zip(h, c)
                      |> Enum.into(%{})
                      |> IO.inspect()
                  end

              _ ->
                {:ok, res} = File.read(params["books"].path)

                {header, contents} =
                  res
                  |> String.split("\r\n")
                  |> List.pop_at(0)

                data =
                  for content <- contents do
                    Enum.zip(
                      header |> String.split(","),
                      content |> String.split(",") |> Enum.map(&(&1 |> String.trim()))
                    )
                    |> Enum.into(%{})
                  end
                  |> IO.inspect()
            end

          {:ok, bu} = United.Settings.create_book_upload()
          United.Settings.upload_books(data, bu)

          # keep a copy of the upload data else modify the uploaded data and write back to csv file for user to modify
          %{status: "ok"}

        "process_loan" ->
          %{
            "barcode" => barcode,
            "btnradio" => _prcess,
            "loan_date" => loan_date,
            "member_code" => member_code,
            "return_date" => return_date,
            "scope" => _scope
          } = params

          bi =
            United.Settings.search_book_inventory(%{"barcode" => barcode}, true) |> List.first()

          m = United.Settings.search_member(%{"member_code" => member_code}, true) |> List.first()

          if United.Settings.book_can_loan(bi.id) |> Enum.count() > 0 do
            %{status: "error"}
          else
            if bi != nil && m != nil do
              case United.Settings.create_loan(%{
                     loan_date: loan_date,
                     return_date: return_date,
                     book_inventory_id: bi.id,
                     member_id: m.id
                   }) do
                {:ok, _p} ->
                  %{status: "ok"}

                _ ->
                  %{status: "error"}
              end
            else
              %{status: "empty"}
            end
          end

        "search_book" ->
          United.Settings.search_book_inventory(params, true)
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        "search_member" ->
          United.Settings.search_member(params, true)
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        "co_failed" ->
          United.Settings.update_customer_order_by_external_id(params["external_id"], :failed)

        "co_paid" ->
          United.Settings.update_customer_order_by_external_id(params["external_id"], :paid)

        "finalize_order" ->
          %{"live_id" => live_id, "order" => order} = params
          IO.inspect(order)
          United.Settings.finalize_order(params)
          %{status: "received"}

        _ ->
          %{status: "received"}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(final))
  end

  def webhook(conn, params) do
    final =
      case params["scope"] do
        "show_book" ->
          United.Settings.get_book_by_isbn(params["isbn"])

        "book_intro" ->
          United.Settings.get_intro_books()
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        # |> Enum.take(1)

        "get_token" ->
          # for member only
          m = United.Settings.get_member_by_email(params["email"])
          # |> BluePotion.s_to_map() 

          United.Settings.member_token(m.id)

        "get_member_profile" ->
          {:ok, map} = Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", params["token"])

          United.Settings.get_member!(map.id)
          |> BluePotion.s_to_map()
          |> Map.delete(:id)
          |> Map.put(:crypted_password, "")

        "get_profile" ->
          case Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", params["token"]) do
            {:ok, map} ->
              United.Settings.get_user!(map.id)
              |> BluePotion.s_to_map()
              |> Map.delete(:id)
              |> Map.put(:crypted_password, "")

            {:error, _expired} ->
              %{status: "expired"}
          end

        "return_book" ->
          United.Settings.return_book(params["loan_id"])
          %{status: "received"}

        "book_can_loan" ->
          United.Settings.book_can_loan(params["book_inventory_id"])
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        "all_outstanding_loans" ->
          United.Settings.all_outstanding_loans()
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        "member_outstanding_loans" ->
          United.Settings.member_outstanding_loans(params["member_id"])
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        "update_co_address" ->
          United.Settings.update_co_address(params)
          %{status: "received"}

        "create_co" ->
          nparams =
            %{
              "account_document_line" => %{
                "VBi6kc" => %{
                  "item_id" => "5",
                  "item_name" => "AYAM STANDARD",
                  "line_total" => "104.40",
                  "qty" => "12",
                  "qty2" => "12",
                  "remarks" => "Fresh farm chicken 60 days",
                  "sub_total" => "104.40",
                  "tax" => "0.00",
                  "tax_code" => "1",
                  "unit_cost" => "8.7"
                }
              },
              "account_documents" => %{
                "account_id" => "880",
                "created_by" => "4",
                "date" => "2022-03-21",
                "document_type" => "customer_order",
                "id" => "0",
                "organization_id" => "2",
                "ref_no" => "<<new>>"
              },
              "model" => "account_documents"
            }
            |> Map.merge(params)

          {:ok, res} = Accounting.post(Jason.encode!(nparams), params["accounting_accesss_token"])

          resp = res.body |> Poison.decode!()

        "get_accounting_products" ->
          body = "products"
          {:ok, res} = Accounting.get(body, params["accounting_accesss_token"])

          resp = res.body |> Poison.decode!()

          IO.inspect(resp)
          United.Settings.save_sync_items(params["accounting_accesss_token"], resp)
          resp

        "repopulate_comments" ->
          lv = United.Settings.get_live_video!(params["live_video_id"])
          FacebookHelper.get_live_video(lv.live_id, lv.facebook_page.page_access_token, lv)

        "process_into_order" ->
          FacebookHelper.page_video_to_orders(params["live_id"])

        "get_videos" ->
          FacebookHelper.page_videos(params["pat"])

        "get_pages" ->
          FacebookHelper.get_user_manage_pages(params["id"])

        "show_blog" ->
          United.Settings.get_blog!(params["id"])
          |> BluePotion.s_to_map()

        "recent_blogs" ->
          United.Settings.list_recent_blogs() |> Enum.map(&BluePotion.s_to_map(&1))

        "gen_inputs" ->
          BluePotion.test_module(params["module"])

        _ ->
          %{status: "received"}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(final))
  end

  require IEx

  def form_submission(conn, params) do
    model = Map.get(params, "model")
    params = Map.delete(params, "model")

    upcase? = fn x -> x == String.upcase(x) end

    sanitized_model =
      model
      |> String.split("")
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(
        &if upcase?.(&1), do: String.replace(&1, &1, "_#{String.downcase(&1)}"), else: &1
      )
      |> Enum.join("")
      |> String.split("")
      |> Enum.reject(&(&1 == ""))
      |> List.pop_at(0)
      |> elem(1)
      |> Enum.join()

    IO.inspect(params)
    json = %{}
    config = Application.get_env(:blue_potion, :contexts)

    mods =
      if config == nil do
        ["Settings", "Secretary"]
      else
        config
      end

    struct =
      for mod <- mods do
        Module.concat([Application.get_env(:blue_potion, :otp_app), mod, model])
      end
      |> Enum.filter(&Code.ensure_compiled?(&1))
      |> List.first()

    IO.inspect(struct)

    mod =
      struct
      |> Module.split()
      |> Enum.take(2)
      |> Module.concat()

    IO.inspect(mod)

    dynamic_code =
      if Map.get(params, model) |> Map.get("id") != "0" do
        """
        struct = #{mod}.get_#{sanitized_model}!(params["id"])
        #{mod}.update_#{sanitized_model}(struct, params)
        """
      else
        """
        #{mod}.create_#{sanitized_model}(params)
        """
      end

    p = Map.get(params, model)

    p =
      case model do
        "Member" ->
          case p["id"] |> Integer.parse() do
            :error ->
              {:ok, map} = Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", p["id"])
              Map.put(p, "id", map.id)

            _ ->
              p
          end

        "User" ->
          case p["id"] |> Integer.parse() do
            :error ->
              {:ok, map} = Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", p["id"])
              Map.put(p, "id", map.id)

            _ ->
              p
          end

        _ ->
          p
      end

    {result, _values} = Code.eval_string(dynamic_code, params: p |> United.upload_file())

    IO.inspect(result)

    case result do
      {:ok, item} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(BluePotion.s_to_map(item)))

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = changeset.errors |> Keyword.keys()

        {reason, message} = changeset.errors |> hd()
        {proper_message, message_list} = message
        final_reason = Atom.to_string(reason) <> " " <> proper_message

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{status: final_reason}))
    end
  end

  def append_params(params) do
    parent_id = Map.get(params, "parent_id")

    params =
      if parent_id != nil do
        params
        |> Map.put(
          "parent_id",
          United.Settings.decode_token(parent_id).id
        )
      else
        params
      end

    password = Map.get(params, "password")

    params =
      if password != nil do
        crypted_password = :crypto.hash(:sha512, password) |> Base.encode16() |> String.downcase()

        params
        |> Map.put(
          "crypted_password",
          crypted_password
        )
      else
        params
      end

    IO.inspect("appended")
    IO.inspect(params)

    params
  end

  def decode_token(params) do
    corporate_account_id = Map.get(params, "corporate_account_id")

    params =
      if corporate_account_id != nil do
        params
        |> Map.put(
          "corporate_account_id",
          United.Settings.decode_token(corporate_account_id).id
        )
      else
        params
      end
  end

  def datatable(conn, params) do
    model = Map.get(params, "model")
    preloads = Map.get(params, "preloads")
    additional_search_queries = Map.get(params, "additional_search_queries")
    params = Map.delete(params, "model") |> Map.delete("preloads")

    additional_search_queries =
      if additional_search_queries == nil do
        ""
      else
        # replace the data inside
        # its a list [column1, column2]
        columns = additional_search_queries |> String.split(",")

        for {item, index} <- columns |> Enum.with_index() do
          if item |> String.contains?("!=") do
            [i, val] = item |> String.split("!=")

            """
            |> where([a], a.#{i} != "#{val}") 
            """
          else
            ss = params["search"]["value"]

            if index > 0 do
              """
              |> or_where([a], ilike(a.#{item}, ^"%#{ss}%"))
              """
            else
              """
              |> where([a], ilike(a.#{item}, ^"%#{ss}%"))
              """
            end
          end
        end
        |> Enum.join("")
      end
      |> IO.inspect()

    preloads =
      if preloads == nil do
        preloads = []
      else
        convert_to_atom = fn data ->
          if is_map(data) do
            items = data |> Map.to_list()

            for {x, y} <- items do
              {String.to_atom(x), String.to_atom(y)}
            end
          else
            String.to_atom(data)
          end
        end

        preloads
        |> Jason.decode!()
        |> IO.inspect()
        |> Enum.map(&(&1 |> convert_to_atom.()))

        # |> Enum.map(&(&1 |> String.to_atom()))
      end
      |> List.flatten()

    IO.inspect(preloads)

    json =
      BluePotion.post_process_datatable(
        params,
        Module.concat(["United", "Settings", model]),
        additional_search_queries,
        preloads
      )

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(json))
  end

  def delete_data(conn, params) do
    model = Map.get(params, "model")
    params = Map.delete(params, "model")

    upcase? = fn x -> x == String.upcase(x) end

    sanitized_model =
      model
      |> String.split("")
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(
        &if upcase?.(&1), do: String.replace(&1, &1, "_#{String.downcase(&1)}"), else: &1
      )
      |> Enum.join("")
      |> String.split("")
      |> Enum.reject(&(&1 == ""))
      |> List.pop_at(0)
      |> elem(1)
      |> Enum.join()

    IO.inspect(params)
    json = %{}

    config = Application.get_env(:blue_potion, :contexts)

    mods =
      if config == nil do
        ["Settings", "Secretary"]
      else
        config
      end

    struct =
      for mod <- mods do
        Module.concat([Application.get_env(:blue_potion, :otp_app), mod, model])
      end
      |> Enum.filter(&({:error, :nofile} != Code.ensure_compiled(&1)))
      |> List.first()

    IO.inspect(struct)

    mod =
      struct
      |> Module.split()
      |> Enum.take(2)
      |> Module.concat()

    IO.inspect(mod)

    dynamic_code = """
    struct = #{mod}.get_#{sanitized_model}!(params["id"])
    #{mod}.delete_#{sanitized_model}(struct)
    """

    {result, _values} = Code.eval_string(dynamic_code, params: params)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "already deleted"}))
  end
end
