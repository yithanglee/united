defmodule FacebookHelper do
  import Ecto.Query
  import UnitedWeb.Gettext
  alias United.{Settings, Repo}

  @app_secret Application.get_env(:united, :facebook)[:app_secret]
  @app_id Application.get_env(:united, :facebook)[:app_id]

  def stream_comments(fb_video_id_str) do
    url =
      "https://streaming-graph.facebook.com/#{fb_video_id_str}/live_comments?access_token=#{
        @page_access_token
      }&comment_rate=one_per_two_seconds&fields=from{name,id},message"

    %HTTPoison.AsyncResponse{id: id} =
      HTTPoison.get!(url, [], stream_to: self(), recv_timeout: :infinity)

    if Process.whereis(String.to_atom("fb_vid_" <> fb_video_id_str)) == nil do
      Process.register(self(), String.to_atom("fb_vid_" <> fb_video_id_str))
      IO.puts("chucking.....\n\n")
      process_httpoison_chunks(id, fb_video_id_str)
    else
      IO.puts("process exist...\n\n")
    end
  end

  def process_httpoison_chunks(id, fb_video_id_str) do
    IO.inspect(self())
    # visitor_company = Repo.get(VisitorCompany, visitor_company_id)

    receive do
      %HTTPoison.AsyncStatus{id: ^id} ->
        # TODO handle status
        process_httpoison_chunks(id, fb_video_id_str)

      %HTTPoison.AsyncHeaders{id: ^id, headers: %{"Connection" => "keep-alive"}} ->
        # TODO handle headers
        process_httpoison_chunks(id, fb_video_id_str)

      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk_data} ->
        IO.puts(chunk_data)

        if chunk_data != ": ping\n\n" and String.contains?(chunk_data, "data:") do
          comment = chunk_data |> String.replace("data: ", "") |> Poison.decode!()
          datetime = Timex.now()
          IO.inspect(comment)
        end

        process_httpoison_chunks(id, fb_video_id_str)

      %HTTPoison.AsyncEnd{id: ^id} ->
        IO.puts("fb_vid_#{fb_video_id_str} ended")
        pid = Process.whereis(String.to_atom("fb_vid_" <> fb_video_id_str))

        Process.exit(pid, :kill)

        # FbEcomWeb.Endpoint.broadcast(
        #   "live_video:#{fb_video_id}",
        #   "notify_video_has_ended",
        #   %{fb_video_id_str: fb_video_id_str}
        # )

        true
    end
  end

  def page_videos(page_access_token) do
    pat = page_access_token
    page = United.Settings.get_facebook_page_by_pat(pat) |> List.first()

    url = "https://graph.facebook.com/#{page.page_id}?fields=live_videos&access_token=#{pat}"

    res = HTTPoison.get(url)

    live =
      case res do
        {:ok, resp} ->
          body = Jason.decode!(resp.body)
          IO.inspect(body)
          %{"live_videos" => %{"data" => videos}} = body
          IO.inspect(videos)

          for %{
                "embed_html" => embed_html,
                "id" => live_id,
                "status" => status
              } = video <- videos do
            check = United.Settings.get_live_video_by_fb_id(live_id)

            live_video =
              if check != nil do
                check
              else
                {:ok, lv} =
                  United.Settings.create_live_video(
                    video
                    |> Map.put("facebook_page_id", page.id)
                    |> Map.put("live_id", live_id)
                    |> Map.delete("id")
                  )

                lv
              end
          end

          live_now = Enum.filter(videos, &(&1["status"] == "LIVE")) |> List.first()

          if live_now != nil do
            check = United.Settings.get_live_video_by_fb_id(live_now["id"])

            live_video =
              if check != nil do
                check
              else
                {:ok, lv} =
                  United.Settings.create_live_video(
                    live_now
                    |> Map.put("facebook_page_id", page.id)
                    |> Map.put("live_id", live_now["id"])
                    |> Map.delete("id")
                  )

                lv
              end

            get_live_video(live_now["id"], pat, live_video)
            # stream_comments()
            Task.start_link(__MODULE__, :stream_comments, [live_now["id"]])

            live_video |> BluePotion.s_to_map()
          end
      end

    %{live: live, all: page.live_videos |> Enum.map(&BluePotion.s_to_map(&1))}
  end

  def get_live_video(live_now, page_access_token, %United.Settings.LiveVideo{} = live_video) do
    IO.inspect(live_video)

    url =
      "https://graph.facebook.com/#{live_now}?fields=comments&access_token=#{page_access_token}"

    res = HTTPoison.get(url)

    case res do
      {:ok, resp} ->
        body = Jason.decode!(resp.body)

        %{"comments" => %{"data" => comments, "paging" => paging}} = body

        for %{
              "created_time" => created_at,
              "from" => %{"id" => psid, "name" => visitor_name},
              "id" => ms_id,
              "message" => message
            } = comment <- comments do
          page_visitor =
            with pv <- United.Settings.get_page_visitor_by_psid(psid),
                 true <- pv != nil do
              pv
            else
              _ ->
                {:ok, pv} = United.Settings.create_page_visitor(%{psid: psid, name: visitor_name})
                pv
            end

          a =
            United.Settings.create_video_comment(%{
              ms_id: ms_id,
              page_visitor_id: page_visitor.id,
              message: message,
              created_at: created_at,
              live_video_id: live_video.id
            })

          a
        end

        if "next" in Map.keys(paging) do
          next_comment_pages(paging["next"], live_video)
        end
    end
  end

  def next_comment_pages(url, %United.Settings.LiveVideo{} = live_video) do
    res = HTTPoison.get(url)

    case res do
      {:ok, resp} ->
        body = Jason.decode!(resp.body)

        %{"data" => comments, "paging" => paging} = body

        for %{
              "created_time" => created_at,
              "from" => %{"id" => psid, "name" => visitor_name},
              "id" => ms_id,
              "message" => message
            } = comment <- comments do
          page_visitor =
            with pv <- United.Settings.get_page_visitor_by_psid(psid),
                 true <- pv != nil do
              pv
            else
              _ ->
                {:ok, pv} = United.Settings.create_page_visitor(%{psid: psid, name: visitor_name})
                pv
            end

          b =
            United.Settings.create_video_comment(%{
              ms_id: ms_id,
              page_visitor_id: page_visitor.id,
              message: message,
              created_at: created_at,
              live_video_id: live_video.id
            })

          IO.inspect(b)
          b
        end

        if "next" in Map.keys(paging) do
          next_comment_pages(paging["next"], live_video)
        end

      _ ->
        nil
    end
  end

  def get_user_manage_pages(user_id) do
    user = United.Settings.get_user_by_fb_user_id(user_id)
    page_ids = user.facebook_pages |> Enum.map(& &1.page_id)

    url =
      "https://graph.facebook.com/#{user_id}/accounts?fields=name,access_token&access_token=#{
        user.user_access_token
      }"

    res = HTTPoison.get(url)

    case res do
      {:ok, resp} ->
        %{"data" => fb_page_list} = Jason.decode!(resp.body)
        # IO.inspect(body) 
        for fb_page <- fb_page_list do
          unless fb_page["id"] in page_ids do
            {:ok, page} =
              United.Settings.create_facebook_page(%{
                user_id: user.id,
                page_id: fb_page["id"],
                name: fb_page["name"],
                page_access_token: fb_page["access_token"]
              })

            page |> BluePotion.s_to_map()
          else
            user.facebook_pages
            |> Enum.filter(&(&1.page_id == fb_page["id"]))
            |> List.first()
            |> BluePotion.s_to_map()
          end
        end
    end
  end

  def get_app_token() do
    url =
      "https://graph.facebook.com/oauth/access_token?client_id=#{@app_id}&client_secret=#{
        @app_secret
      }&grant_type=client_credentials"

    res = HTTPoison.get(url)

    case res do
      {:ok, resp} ->
        body = Jason.decode!(resp.body)
        IO.inspect(body)
    end
  end

  def inspect_token(token) do
    %{
      "access_token" => app_token,
      "token_type" => token2
    } = get_app_token()

    url = "https://graph.facebook.com/debug_token?input_token=#{token}&access_token=#{app_token}"
    IO.inspect(url)
    res = HTTPoison.get(url)

    case res do
      {:ok, resp} ->
        body = Jason.decode!(resp.body)
        IO.inspect(body)
    end
  end

  def get_user_access_token() do
    res =
      HTTPoison.get(
        "https://graph.facebook.com/oauth/access_token?grant_type=fb_exchange_token&client_id=#{
          @app_id
        }&client_secret=#{@app_secret}&fb_exchange_token=#{@user_access_token}"
      )

    case res do
      {:ok, resp} ->
        %{"access_token" => access_token, "token_type" => token_type} = Jason.decode!(resp.body)
        IO.inspect(access_token)
    end
  end

  def create_identities(webhook_event, sender_psid) do
    company = Repo.get_by(User, page_id: webhook_event["recipient"]["id"])

    company =
      if company == nil do
        {:ok, company} =
          Settings.create_company(%{
            page_id: webhook_event["recipient"]["id"]
          })

        company
      else
        company
      end

    vc = Repo.get_by(VisitorCompany, psid: sender_psid)

    vc =
      if vc == nil do
        {:ok, vc} =
          FbTool.Settings.create_visitor_company(%{
            psid: webhook_event["sender"]["id"],
            recepient_id: webhook_event["recipient"]["id"],
            company_id: company.id
          })

        vc
      else
        vc
      end

    # Task.start_link(__MODULE__, :update_fb_vc, [sender_psid, vc])
    update_fb_vc(sender_psid, vc)
  end

  def update_fb_vc(sender_psid, vc) do
    company = Repo.get(Company, vc.company_id)

    if company.page_access_token != nil do
      response =
        HTTPoison.get!(
          "https://graph.facebook.com/v7.0/#{sender_psid}?access_token=#{
            company.page_access_token
          }"
        )

      body = response.body
      IO.puts(body)
      {:ok, map_user} = Jason.decode(body)
      name = map_user["first_name"] <> " " <> map_user["last_name"]

      res = Repo.all(from v in Visitor, where: v.name == ^name)

      visitor =
        if res == [] do
          {:ok, visitor} = Settings.create_visitor(%{name: name})
          visitor
        else
          hd(res)
        end

      pc =
        if map_user["profile_pic"] != nil do
          map_user["profile_pic"]
        else
          nil
        end

      {:ok, visitor} = FbTool.Settings.update_visitor(visitor, %{name: name, image_url: pc})

      Settings.update_visitor_company(vc, %{visitor_id: visitor.id})
    end
  end

  def handleMessage(sender_psid, received_message) do
    IO.inspect(received_message)
    vc = Repo.get_by(VisitorCompany, psid: sender_psid)
    visitor = Repo.get(Visitor, vc.visitor_id)
    lang = "en"
    # visitor.lang
    Gettext.put_locale(FbToolWeb.Gettext, lang)

    # buy product

    # check order

    responses =
      cond do
        received_message["text"] != nil ->
          text = String.downcase(received_message["text"])

          cond do
            text == "hi" ->
              [
                %{
                  "attachment" => %{
                    "type" => "template",
                    "payload" => %{
                      "template_type" => "button",
                      "text" =>
                        gettext(
                          "hi! Thanks for reaching out! Please choose the following to continue. "
                        ),
                      "buttons" => [
                        %{
                          "type" => "postback",
                          "title" => "Buy Product",
                          "payload" => "buy_product"
                        },
                        %{
                          "type" => "postback",
                          "title" => "Check Order",
                          "payload" => "check_order"
                        }
                      ]
                    }
                  }
                }
              ]

            vc.msg_state == "form_line1" ->
              {:ok, vc} = Settings.update_visitor(visitor, %{line1: text})

              {:ok, vc} = FbTool.Settings.update_visitor_company(vc, %{msg_state: "form_city"})

              [
                %{
                  "text" => gettext("After type in the city, press enter:")
                }
              ]

            vc.msg_state == "form_city" ->
              {:ok, vc} = Settings.update_visitor(visitor, %{town: text})

              {:ok, vc} =
                FbTool.Settings.update_visitor_company(vc, %{msg_state: "form_postcode"})

              [
                %{
                  "text" => gettext("After type in the postcode, press enter:")
                }
              ]

            vc.msg_state == "form_postcode" ->
              {:ok, vc} = Settings.update_visitor(visitor, %{postcode: text})

              {:ok, vc} = FbTool.Settings.update_visitor_company(vc, %{msg_state: "form_state"})

              [
                %{
                  "text" => gettext("After type in the state, press enter:")
                }
              ]

            vc.msg_state == "form_state" ->
              {:ok, vc} = Settings.update_visitor(visitor, %{state: text})

              {:ok, vc} = FbTool.Settings.update_visitor_company(vc, %{msg_state: "checkout"})

              existing_carts =
                Repo.all(
                  from c in Cart,
                    where: c.status == ^"Pending Checkout" and c.visitor_id == ^vc.id
                )

              cart = hd(existing_carts)

              {:ok, cart} =
                Settings.update_cart(cart, %{
                  line1: visitor.line1,
                  town: visitor.town,
                  state: visitor.state,
                  postcode: visitor.postcode
                })

              [
                receipt_template(cart, vc),
                %{
                  "attachment" => %{
                    "type" => "template",
                    "payload" => %{
                      "template_type" => "button",
                      "text" => gettext("What would you like to do now? "),
                      "buttons" => [
                        %{
                          "type" => "postback",
                          "title" => "Make Payment",
                          "payload" => "pay_now"
                        },
                        %{
                          "type" => "postback",
                          "title" => "Change address",
                          "payload" => "form_line1"
                        },
                        %{
                          "type" => "postback",
                          "title" => "Continue Shopping",
                          "payload" => "buy_product"
                        }
                      ]
                    }
                  }
                }
              ]

            true ->
              {:ok, vc} = FbTool.Settings.update_visitor_company(vc, %{msg_state: "idle"})
              [%{"text" => gettext("hi! We will get a human agent to contact you asap.")}]
          end

        received_message["attachments"] != nil ->
          [%{"text" => gettext("hi! We dont process attachments at the moment.")}]
      end

    callSendAPI(sender_psid, responses)
  end

  # button type postback, web_url 
  # nid postback button 0, payload
  # 
  def button_template(
        title,
        url,
        button_type_index \\ 1,
        payload \\ "end_check"
      ) do
    button_type = ["postback", "web_url"]

    case button_type_index do
      0 ->
        %{
          "type" => "postback",
          "title" => title,
          "payload" => payload
        }

      1 ->
        %{
          "type" => "web_url",
          "url" => "https://organiclovenewlife.com/#{url}",
          "title" => title
        }
    end
  end

  def tile_template(
        title,
        subtitle,
        image_url,
        button_list,
        button_url,
        payload \\ "end_check"
      ) do
    tile_type = %{
      "type" => "web_url",
      "url" => "https://organiclovenewlife.com/#{button_url}",
      "webview_height_ratio" => "tall"
    }

    %{
      "title" => title,
      "image_url" => "https://organiclovenewlife.com/#{image_url}",
      "subtitle" => subtitle,
      "default_action" => tile_type,
      "buttons" => button_list
    }
  end

  def list_template(list_of_tiles) do
    %{
      "attachment" => %{
        "type" => "template",
        "payload" => %{
          "template_type" => "generic",
          "elements" => list_of_tiles
        }
      }
    }
  end

  def handlePostback(sender_psid, received_postback) do
    vc = Repo.get_by(VisitorCompany, psid: sender_psid)

    visitor = Repo.get(Visitor, vc.visitor_id)
    lang = "en"

    payload = received_postback["payload"]

    IO.puts(payload)

    [code, value] = String.split(payload, "_")

    responses =
      cond do
        payload == "check_order" ->
          existing_carts =
            Repo.all(
              from c in Cart,
                where: c.status == ^"Pending Checkout" and c.visitor_id == ^visitor.id
            )

          if existing_carts != [] do
            [
              receipt_template(hd(existing_carts), visitor),
              %{
                "attachment" => %{
                  "type" => "template",
                  "payload" => %{
                    "template_type" => "button",
                    "text" => gettext("What would you like to do now? "),
                    "buttons" => [
                      %{
                        "type" => "postback",
                        "title" => "Make Payment",
                        "payload" => "pay_now"
                      },
                      %{
                        "type" => "postback",
                        "title" => "Change address",
                        "payload" => "form_line1"
                      },
                      %{
                        "type" => "postback",
                        "title" => "Continue Shopping",
                        "payload" => "buy_product"
                      }
                    ]
                  }
                }
              }
            ]
          else
            [
              %{
                "attachment" => %{
                  "type" => "template",
                  "payload" => %{
                    "template_type" => "button",
                    "text" =>
                      gettext(
                        "There's no pending checkout orders. Please choose the following to continue. "
                      ),
                    "buttons" => [
                      %{
                        "type" => "postback",
                        "title" => "Buy Product",
                        "payload" => "buy_product"
                      },
                      %{
                        "type" => "postback",
                        "title" => "Check Order",
                        "payload" => "check_order"
                      }
                    ]
                  }
                }
              }
            ]
          end

        payload == "buy_product" ->
          # products = Repo.all(from p in Settings.Product, limit: 10)

          # list_of_tiles =
          #   for product <- products do
          #     price =
          #       if product.promo_price != nil do
          #         product.promo_price
          #       else
          #         product.selling_price
          #       end

          #     tile_template(
          #       product.name,
          #       product.short_desc,
          #       product.img_url,
          #       [
          #         button_template(
          #           "how to use",
          #           "/products/#{product.id}",
          #           1
          #         ),
          #         button_template("Add to cart (#{price})", "", 0, "atc_#{product.id}"),
          #         button_template("Remove from cart", "", 0, "rfc_#{product.id}")
          #       ],
          #       "/products/#{product.id}",
          #       "viewproduct_#{product.id}"
          #     )
          #   end

          # resps = list_template(list_of_tiles)
          resps = %{}

          [
            %{
              "text" => "We have the following products!"
            }
          ] ++ [resps]

        payload == "end_check" ->
          [
            %{
              "text" => "Thank you for your patronage!"
            }
          ]

        payload == "get_started" ->
          [
            %{
              "attachment" => %{
                "type" => "template",
                "payload" => %{
                  "template_type" => "button",
                  "text" => "Hi! Welcome to meshume!\nChoose a language.",
                  "buttons" => [
                    %{"type" => "postback", "title" => "English", "payload" => "lang_en"},
                    %{"type" => "postback", "title" => "中文", "payload" => "lang_zh"}
                  ]
                }
              }
            }
          ]

        payload == "lang_zh" ->
          FbTool.Settings.update_visitor(visitor, %{lang: "zh"})
          Gettext.put_locale(EcomBackendWeb.Gettext, "zh")

          [
            %{
              "text" => "你好！输入menu来开始！"
            }
          ]

        payload == "lang_en" ->
          FbTool.Settings.update_visitor(visitor, %{lang: "en"})
          Gettext.put_locale(EcomBackendWeb.Gettext, "en")

          [
            %{
              "text" => "Welcome! Type 'menu' to get started!"
            }
          ]

        payload == "checkout_now" ->
          existing_carts =
            Repo.all(
              from c in Cart,
                where: c.status == ^"Pending Checkout" and c.visitor_id == ^visitor.id
            )

          [
            receipt_template(hd(existing_carts), visitor),
            %{
              "attachment" => %{
                "type" => "template",
                "payload" => %{
                  "template_type" => "button",
                  "text" => gettext("What would you like to do now? "),
                  "buttons" => [
                    %{
                      "type" => "postback",
                      "title" => "Make Payment",
                      "payload" => "pay_now"
                    },
                    %{
                      "type" => "postback",
                      "title" => "Change address",
                      "payload" => "form_line1"
                    },
                    %{
                      "type" => "postback",
                      "title" => "Continue Shopping",
                      "payload" => "buy_product"
                    }
                  ]
                }
              }
            }
          ]

        # code == "atc" ->
        #   # check if the visitor has a cart created...
        #   existing_carts =
        #     Repo.all(
        #       from c in Cart,
        #         where: c.status == ^"Pending Checkout" and c.visitor_id == ^visitor.id
        #     )

        #   gmt = Timex.now() |> Timex.shift(hours: 8)

        #   cart =
        #     if existing_carts == [] do
        #       {:ok, cart} =
        #         Settings.create_cart(%{
        #           "status" => "Pending Checkout",
        #           "visitor_id" => visitor.id,
        #           "day" => gmt.day,
        #           "month" => gmt.month,
        #           "year" => gmt.year,
        #           "company_id" => 0
        #         })

        #       cart
        #     else
        #       hd(existing_carts)
        #     end

        #   pp = Repo.get(Settings.Product, value)

        #   unit_price = pp.promo_price |> String.replace("RM ", "") |> Float.parse() |> elem(0)

        #   final_price = unit_price * 1
        #   final_weight = pp.weight_kg * 1

        #   data_list =
        #     if cart.json_items != nil do
        #       items = cart.json_items |> Jason.decode!()

        #       need_add = Enum.any?(items, fn x -> x["id"] == pp.id end)

        #       list =
        #         for item <- items do
        #           i = Repo.get(Settings.Product, item["product_id"])

        #           price =
        #             if i.promo_price != nil do
        #               i.promo_price
        #             else
        #               i.selling_price
        #             end

        #           unit_price = price |> String.replace("RM ", "") |> Float.parse() |> elem(0)

        #           qty =
        #             if pp.id == item["id"] do
        #               item["qty"] + 1
        #             else
        #               item["qty"]
        #             end

        #           final_price = unit_price * qty
        #           final_weight = i.weight_kg * qty
        #           {final_weight, final_price}
        #         end

        #       if need_add do
        #         list
        #       else
        #         list ++ [{final_weight, final_price}]
        #       end
        #     else
        #       # add new item to the json items.. 
        #       [{final_weight, final_price}]
        #     end

        #   map = FbTool.s_to_map(pp)

        #   itemz =
        #     map
        #     |> Map.delete(:long_d_desc)
        #     |> Map.delete(:short_desc)
        #     |> Map.put(:qty, 1)
        #     |> Map.put(:product_id, pp.id)

        #   json_items =
        #     if cart.json_items != nil do
        #       items = cart.json_items |> Jason.decode!()
        #       IO.inspect(items)
        #       need_add = Enum.any?(items, fn x -> x["id"] == itemz.id end)

        #       lists =
        #         for item <- items do
        #           if itemz.id == item["id"] do
        #             FbTool.string_to_atom(item, Map.keys(item)) |> Map.put(:qty, item["qty"] + 1)
        #           else
        #             FbTool.string_to_atom(item, Map.keys(item))
        #           end
        #         end
        #         |> Enum.reject(fn x -> x == nil end)

        #       if need_add do
        #         lists
        #       else
        #         lists ++ [itemz]
        #       end
        #     else
        #       [itemz]
        #     end

        #   sub_total =
        #     data_list
        #     |> Enum.map(fn x -> elem(x, 1) end)
        #     |> Enum.sum()

        #   weight =
        #     data_list
        #     |> Enum.map(fn x -> elem(x, 0) end)
        #     |> Enum.sum()

        #   company_tax = 1.00

        #   {:ok, cart} =
        #     Settings.update_cart(cart, %{
        #       "sub_total" => sub_total,
        #       "json_items" => Jason.encode!(json_items)
        #     })

        #   IO.inspect(json_items)

        #   final_list =
        #     for item <- json_items do
        #       %{"text" => "#{item.name}\r\n#{item.qty}"}
        #     end

        #   button =
        #     if visitor.line1 == nil do
        #       %{"type" => "postback", "title" => "Yes", "payload" => "form_line1"}
        #     else
        #       %{"type" => "postback", "title" => "Yes", "payload" => "checkout_now"}
        #     end

        #   [%{"text" => gettext("Your current cart has:")}] ++
        #     final_list ++
        #     [
        #       %{
        #         "attachment" => %{
        #           "type" => "template",
        #           "payload" => %{
        #             "template_type" => "button",
        #             "text" => "Would you like to check out ?",
        #             "buttons" => [
        #               button,
        #               %{"type" => "postback", "title" => "Later", "payload" => "buy_product"}
        #             ]
        #           }
        #         }
        #       }
        #     ]

        # code == "rfc" ->
        #   # check if the visitor has a cart created...
        #   existing_carts =
        #     Repo.all(
        #       from c in Cart,
        #         where: c.status == ^"Pending Checkout" and c.visitor_id == ^visitor.id
        #     )

        #   gmt = Timex.now() |> Timex.shift(hours: 8)

        #   cart =
        #     if existing_carts == [] do
        #       {:ok, cart} =
        #         Settings.create_cart(%{
        #           "status" => "Pending Checkout",
        #           "visitor_id" => visitor.id,
        #           "day" => gmt.day,
        #           "month" => gmt.month,
        #           "year" => gmt.year,
        #           "company_id" => 0
        #         })

        #       cart
        #     else
        #       hd(existing_carts)
        #     end

        #   pp = Repo.get(Settings.Product, value)

        #   unit_price = pp.promo_price |> String.replace("RM ", "") |> Float.parse() |> elem(0)

        #   final_price = unit_price * 1
        #   final_weight = pp.weight_kg * 1

        #   data_list =
        #     if cart.json_items != nil do
        #       items = cart.json_items |> Jason.decode!()

        #       need_deduct = Enum.any?(items, fn x -> x["id"] == pp.id end)

        #       list =
        #         for item <- items do
        #           i = Repo.get(Settings.Product, item["product_id"])

        #           price =
        #             if i.promo_price != nil do
        #               i.promo_price
        #             else
        #               i.selling_price
        #             end

        #           unit_price = price |> String.replace("RM ", "") |> Float.parse() |> elem(0)

        #           qty =
        #             if pp.id == item["id"] do
        #               item["qty"] - 1
        #             else
        #               item["qty"]
        #             end

        #           final_price = unit_price * qty
        #           final_weight = i.weight_kg * qty
        #           {final_weight, final_price}
        #         end

        #       list
        #     else
        #       # add new item to the json items.. 
        #       []
        #     end

        #   map = FbTool.s_to_map(pp)

        #   itemz =
        #     map
        #     |> Map.delete(:long_d_desc)
        #     |> Map.delete(:short_desc)
        #     |> Map.put(:qty, 1)
        #     |> Map.put(:product_id, pp.id)

        #   json_items =
        #     if cart.json_items != nil do
        #       items = cart.json_items |> Jason.decode!()
        #       IO.inspect(items)
        #       need_add = Enum.any?(items, fn x -> x["id"] == itemz.id end)

        #       lists =
        #         for item <- items do
        #           if itemz.id == item["id"] do
        #             FbTool.string_to_atom(item, Map.keys(item)) |> Map.put(:qty, item["qty"] - 1)
        #           else
        #             FbTool.string_to_atom(item, Map.keys(item))
        #           end
        #         end
        #         |> Enum.reject(fn x -> x.qty < 1 end)

        #       if need_add do
        #         lists
        #       else
        #         lists ++ [itemz]
        #       end
        #     else
        #       [itemz]
        #     end

        #   sub_total =
        #     data_list
        #     |> Enum.map(fn x -> elem(x, 1) end)
        #     |> Enum.sum()

        #   weight =
        #     data_list
        #     |> Enum.map(fn x -> elem(x, 0) end)
        #     |> Enum.sum()

        #   company_tax = 1.00

        #   {:ok, cart} =
        #     Settings.update_cart(cart, %{
        #       "sub_total" => sub_total,
        #       "json_items" => Jason.encode!(json_items)
        #     })

        #   IO.inspect(json_items)

        #   final_list =
        #     for item <- json_items do
        #       %{"text" => "#{item.name}\r\nTotal: #{item.qty}"}
        #     end

        #   button =
        #     if visitor.line1 == nil do
        #       %{"type" => "postback", "title" => "Yes", "payload" => "form_line1"}
        #     else
        #       %{"type" => "postback", "title" => "Yes", "payload" => "checkout_now"}
        #     end

        #   [%{"text" => gettext("Your current cart has:")}] ++
        #     final_list ++
        #     [
        #       %{
        #         "attachment" => %{
        #           "type" => "template",
        #           "payload" => %{
        #             "template_type" => "button",
        #             "text" => "Would you like to check out ?",
        #             "buttons" => [
        #               button,
        #               %{"type" => "postback", "title" => "Later", "payload" => "buy_product"}
        #             ]
        #           }
        #         }
        #       }
        #     ]

        code == "form" ->
          text =
            case value do
              "line1" ->
                FbTool.Settings.update_visitor_company(vc, %{msg_state: "form_line1"})

                %{
                  "text" =>
                    gettext(
                      "We need your delivery address, after type in the line1 address, press enter:"
                    )
                }
            end

          [text]

        true ->
          FbTool.Settings.update_visitor(vc, %{msg_state: "idle"})
          [%{"text" => gettext("Oops, try selecting another option!")}]
      end

    callSendAPI(sender_psid, responses)
  end

  def receipt_template(cart, visitor) do
    json_items =
      for item <- cart.json_items |> Jason.decode!() do
        item = FbTool.string_to_atom(item, Map.keys(item))

        price =
          if item.promo_price != nil do
            item.promo_price
          else
            item.selling_price
          end

        %{
          "title" => item.name,
          "subtitle" => item.category,
          "quantity" => item.qty,
          "price" => price |> String.replace("RM ", "") |> Float.parse() |> elem(0),
          "currency" => "MYR",
          "image_url" => "https://organiclovenewlife.com/#{item.img_url}"
        }
      end

    dt = DateTime.utc_now() |> DateTime.to_unix()

    {:ok, cart} =
      Settings.update_cart(cart, %{
        line1: visitor.line1,
        town: visitor.town,
        postcode: visitor.postcode,
        state: visitor.state
      })

    %{
      "attachment" => %{
        "type" => "template",
        "payload" => %{
          "template_type" => "receipt",
          "recipient_name" => visitor.name,
          "order_number" => cart.id,
          "currency" => "MYR",
          "payment_method" => "bank_transfer",
          "order_url" => "",
          "timestamp" => "#{dt}",
          "address" => %{
            "street_1" => cart.line1,
            "city" => cart.town,
            "postal_code" => cart.postcode,
            "state" => cart.state,
            "country" => "Malaysia"
          },
          "summary" => %{
            "subtotal" => cart.sub_total,
            "shipping_cost" => 0.0,
            "total_tax" => 0.0,
            "total_cost" => cart.sub_total
          },
          "elements" => json_items
        }
      }
    }
  end

  def callSendAPI(sender_psid, responses) do
    vc = Repo.get_by(VisitorCompany, psid: sender_psid)

    for response <- responses |> Enum.reject(fn x -> x == nil end) do
      request_body = %{"recipient" => %{"id" => sender_psid}, "message" => response}
      page_access_token = Repo.get_by(Settings.Parameter, name: "page_access_token").cvalue
      {:ok, body_request} = Jason.encode(request_body)
      IO.puts(body_request)
      query = "access_token=#{page_access_token}"
      uri = "https://graph.facebook.com/v7.0/me/messages?#{query}"
      HTTPoison.start()
      IO.puts("start to send to facebook...")

      case HTTPoison.request(:post, uri, body_request, [{"Content-Type", "application/json"}], []) do
        {:ok, %HTTPoison.Response{body: body}} ->
          IO.puts(body)
          IO.puts("message sent!")

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect(reason)

        {:ok, %HTTPoison.Response{status_code: 500, body: body}} ->
          IO.puts(body)
          IO.puts("message sent!")

        _ ->
          IO.puts("dont know how to catch this")
      end
    end
  end
end
