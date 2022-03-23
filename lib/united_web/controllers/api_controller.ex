defmodule UnitedWeb.ApiController do
  use UnitedWeb, :controller

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

        for item <- entry_list do
          %{
            "time" => time,
            "messaging" => messages,
            "id" => fb_page_id
          } = item

          page = United.Repo.get_by(United.Settings.FacebookPage, page_id: fb_page_id)

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

    {result, _values} =
      Code.eval_string(dynamic_code, params: Map.get(params, model) |> United.upload_file())

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

  def datatable(conn, params) do
    model = Map.get(params, "model")
    preloads = Map.get(params, "preloads")
    params = Map.delete(params, "model") |> Map.delete("preloads")

    preloads =
      if preloads == nil do
        preloads = []
      else
        [preloads] |> Enum.map(&(&1 |> String.to_atom()))
      end

    json =
      BluePotion.post_process_datatable(
        params,
        Module.concat(["United", "Settings", model]),
        preloads
      )

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(json))
  end
end
