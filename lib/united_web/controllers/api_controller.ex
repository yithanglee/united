defmodule UnitedWeb.ApiController do
  use UnitedWeb, :controller
  import Mogrify

  require Logger
  alias United.Settings

  def webhook_post(conn, params) do
    final =
      case params["scope"] do
        "reserve_book" ->
          {:ok, map} = Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", params["token"])
          user = Settings.get_member!(map.id) |> IO.inspect()

          attrs = %{
            member_id: user.id,
            book_inventory_id: params["book_inventory_id"]
          }

          if Settings.check_reservation(attrs) do
            Settings.create_reservation(attrs)
            %{status: "ok"}
          else
            %{status: "error", reason: "Reserved!"} |> IO.inspect()
          end

        "page_section" ->
          %{status: "ok"}

        "remove_bi_to_tag" ->
          Settings.remove_bi_to_tag(params)
          %{status: "ok"}

        "assign_bi_to_tag" ->
          Settings.assign_bi_to_tag(params)
          %{status: "ok"}

        "google_signin" ->
          sample = %{
            "result" => %{
              "email" => "yithanglee@gmail.com",
              "name" => "damien lee",
              "uid" => "c3x50ZfwgubqWHrqqz5VCkmkwtg2"
            },
            "scope" => "google_signin"
          }

          res = params["result"]

          {:ok, member} = Settings.lazy_get_member(res["email"], res["name"], res["uid"])

          token =
            Phoenix.Token.sign(
              UnitedWeb.Endpoint,
              "signature",
              BluePotion.s_to_map(member) |> Map.take([:id, :name])
            )

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

          Settings.strong_search_book_inventory(q)
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        "update_member_profile" ->
          {:ok, map} = Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", params["token"])
          user = Settings.get_member!(map.id)
          res = Settings.update_member(user, BluePotion.upload_file(params["Member"]))

          case res do
            {:ok, u} ->
              %{status: "ok"}

            {:error, cg} ->
              IO.inspect(cg)
              %{status: "error"}
          end

        "update_profile" ->
          {:ok, map} = Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", params["token"])
          user = Settings.get_user!(map.id)
          res = Settings.update_user(user, BluePotion.upload_file(params["User"]))

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
            end

          {:ok, bu} = Settings.create_book_upload()
          Settings.upload_books(data, bu)

          # keep a copy of the upload data else modify the uploaded data and write back to csv file for user to modify
          %{status: "ok"}

        "process_loan" ->
          sampple = %{
            "barcode" => "UU100003",
            "loan_date" => "2022-05-19",
            "member_code" => "20225-005",
            "return_date" => "2022-06-02",
            "scope" => "process_loan"
          }

          %{
            "barcode" => barcode,
            "loan_date" => loan_date,
            "member_code" => member_code,
            "return_date" => return_date,
            "scope" => _scope
          } = params

          bi =
            Settings.search_book_inventory(
              %{"barcode" => barcode |> String.replace(" ", "")},
              true
            )
            |> List.first()
            |> IO.inspect()

          m = Settings.search_member(%{"member_code" => member_code}, true) |> List.first()

          # check if member is already approved...
          if m.is_approved && bi != nil do
            if Settings.book_can_loan(bi.id) |> Enum.count() > 0 do
              %{status: "error", reason: "Book already loaned."}
            else
              reservation_data = Settings.is_next_reserved_member(m, bi)

              if reservation_data.can_loan do
                if bi != nil && m != nil do
                  case Settings.create_loan(%{
                         reservation: reservation_data.reservation,
                         loan_date: loan_date,
                         return_date: return_date,
                         book_inventory_id: bi.id,
                         member_id: m.id
                       }) do
                    {:ok, _p} ->
                      %{status: "ok"}

                    _ ->
                      %{status: "error", reason: "Loan issue."}
                  end
                else
                  %{status: "error", reason: "Book, member missing in action."}
                end
              else
                %{
                  status: "error",
                  reason:
                    "This book is reserved for another member (#{reservation_data.member.code})."
                }
              end
            end
          else
            if bi == nil do
              %{status: "error", reason: "Barcode not recognized."}
            else
              %{status: "error", reason: "Not yet approved by admins."}
            end
          end

        "search_book" ->
          Settings.search_book_inventory(params, true)
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        "search_member" ->
          Settings.search_member(params, true)
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

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
        "send_outstanding_emails" ->
          Settings.send_outstanding_emails()
          %{status: "received"}

        "is_next_reserved_member" ->
          %{
            "barcode" => barcode,
            "member_code" => member_code,
            "scope" => _scope
          } = params

          bi =
            Settings.search_book_inventory(
              %{"barcode" => barcode |> String.replace(" ", "")},
              true
            )
            |> List.first()
            |> IO.inspect()

          m = Settings.search_member(%{"member_code" => member_code}, true) |> List.first()

          res = Settings.is_next_reserved_member(m, bi)

          case res do
            %{can_loan: can_loan, member: member} ->
              %{can_loan: can_loan, member: member |> BluePotion.sanitize_struct()}

            %{can_loan: true, reservation: reservation} ->
              %{can_loan: true, reservation: reservation |> BluePotion.sanitize_struct()}

            _ ->
              %{can_loan: false, reservation: nil}
          end

        "check_holiday" ->
          res =
            Settings.get_holiday_by_date(params["event_date"])
            |> BluePotion.sanitize_struct()

          %{status: "ok", holiday: res}

        "statistic" ->
          Settings.statistic(params)

        "has_check_in" ->
          {:ok, map} = Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", params["token"])

          member = Settings.get_member!(map.id)

          if member.has_check_in do
            %{status: "ok"}
          else
            %{status: "error"}
          end

        "check_out_member" ->
          Settings.check_out(params["code"])
          %{status: "ok"}

        "check_in_member" ->
          Settings.check_in(params["code"])
          %{status: "ok"}

        "get_check_in" ->
          {:ok, map} = Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", params["token"])

          member = Settings.get_member!(map.id)

          length = 10
          code = :crypto.strong_rand_bytes(length) |> Base.encode64() |> binary_part(0, length)
          # everytime request, keep update the member;

          Settings.update_member(member, %{qrcode: code})
          code

        "page_section" ->
          Settings.get_page_section_name(params["section"])
          |> BluePotion.s_to_map()

        "book_data" ->
          bi = Settings.book_data(params)

          # get all the book categories book
          book_category = bi.book_category

          all_books =
            book_category
            |> United.Repo.preload([:book_inventories])
            |> Map.get(:book_inventories)

          outstanding_loans = Settings.book_can_loan(bi.id)

          return_date =
            if outstanding_loans != [] do
              List.first(outstanding_loans).return_date
            else
              ""
            end

          bi
          |> BluePotion.sanitize_struct()
          |> Map.put(:category_books, all_books |> Enum.map(& &1.id) |> Enum.sort())
          |> Map.put(:available, outstanding_loans == [])
          |> Map.put(:return_date, return_date)

        "get_tag_books" ->
          Settings.get_tag_books(params)
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        "reassign_categories" ->
          Settings.repopulate_categories()
          %{status: "ok"}

        "show_book" ->
          Settings.get_book_by_isbn(params["isbn"])

        "book_intro" ->
          Settings.get_intro_books()
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        # |> Enum.take(1)

        "get_token" ->
          # for member only
          m = Settings.get_member_by_email(params["email"])
          # |> BluePotion.s_to_map() 

          Settings.member_token(m.id)

        "get_member_profile" ->
          {:ok, map} = Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", params["token"])
          # put the reserve book details...

          member = Settings.get_member!(map.id)

          reservations =
            Settings.get_member_outstanding_reservations(member)
            |> Enum.map(&(&1 |> BluePotion.sanitize_struct()))

          member
          |> BluePotion.sanitize_struct()
          |> Map.delete(:id)
          |> Map.put(:reservations, reservations)
          |> Map.put(:crypted_password, "")

        "get_profile" ->
          case Phoenix.Token.verify(UnitedWeb.Endpoint, "signature", params["token"]) do
            {:ok, map} ->
              Settings.get_user!(map.id)
              |> BluePotion.s_to_map()
              |> Map.delete(:id)
              |> Map.put(:crypted_password, "")

            {:error, _expired} ->
              %{status: "expired"}
          end

        "extend_book" ->
          l = Settings.get_loan!(params["loan_id"])

          if l.has_extended do
            # Settings.extend_book(params["loan_id"])
            %{status: "error", reason: "Book already extended, kindly return this book when due."}
          else
            if Date.compare(Date.utc_today(), l.return_date) == :gt do
              %{
                status: "error",
                reason: "Book is beyond extension, kindly return this book when due."
              }
            else
              Settings.extend_book(params["loan_id"])
              %{status: "received"}
            end
          end

        "return_book" ->
          Settings.return_book(params["loan_id"])
          %{status: "received"}

        "book_can_loan" ->
          Settings.book_can_loan(params["book_inventory_id"])
          |> Enum.map(&(&1 |> BluePotion.s_to_map()))

        "all_outstanding_loans" ->
          insert_fine = fn map ->
            fine_amount = map.member.group.fine_amount
            fine_days = map.member.group.fine_days

            qty = (Date.diff(Date.utc_today(), map.return_date) / fine_days) |> Float.round()

            map
            |> Map.put(:late_days, Date.diff(Date.utc_today(), map.return_date))
            |> Map.put(:fine_amount, fine_amount * qty)
            |> IO.inspect()
          end

          Settings.all_outstanding_loans()
          |> Enum.map(&(&1 |> BluePotion.sanitize_struct() |> insert_fine.()))

        "member_outstanding_loans" ->
          insert_fine = fn map ->
            fine_amount = map.member.group.fine_amount
            fine_days = map.member.group.fine_days

            qty = (Date.diff(Date.utc_today(), map.return_date) / fine_days) |> Float.round()

            map
            |> Map.put(:late_days, Date.diff(Date.utc_today(), map.return_date))
            |> Map.put(:fine_amount, fine_amount * qty)
            |> IO.inspect()
          end

          Settings.member_outstanding_loans(params["member_id"])
          |> Enum.map(&(&1 |> BluePotion.sanitize_struct() |> insert_fine.()))

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
      |> Enum.filter(&Code.ensure_compiled(&1))
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
          Settings.decode_token(parent_id).id
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
          Settings.decode_token(corporate_account_id).id
        )
      else
        params
      end
  end

  def datatable(conn, params) do
    model = Map.get(params, "model")
    preloads = Map.get(params, "preloads")
    additional_search_queries = Map.get(params, "additional_search_queries")
    additional_join_statements = Map.get(params, "additional_join_statements") |> IO.inspect()
    params = Map.delete(params, "model") |> Map.delete("preloads")

    additional_join_statements =
      if additional_join_statements == nil do
        ""
      else
        joins = additional_join_statements |> Poison.decode!()

        for join <- joins do
          key = Map.keys(join) |> List.first()
          value = join |> Map.get(key)

          config = Application.get_env(:blue_potion, :contexts)

          mods =
            if config == nil do
              ["Settings", "Secretary"]
            else
              config
            end

          struct =
            for mod <- mods do
              Module.concat([Application.get_env(:blue_potion, :otp_app), mod, key])
            end
            |> IO.inspect()
            |> Enum.filter(&(elem(Code.ensure_compiled(&1), 0) == :module))
            |> IO.inspect()
            |> List.first()

          # "|> join(:left, [a], b in #{struct}, on: a.#{value} == b.id)"

          "|> join(:left, [a], b in assoc(a, :#{key}))"
        end
        |> Enum.join("")
      end
      |> IO.inspect()

    IO.puts("search query")

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
              if item |> String.contains?("b.") do
                item = item |> String.replace("b.", "")

                # if possible, here need to add back the previous and statements

                """
                |> or_where([a, b], ilike(b.#{item}, ^"%#{ss}%"))
                """
              else
                """
                |> or_where([a], ilike(a.#{item}, ^"%#{ss}%"))
                """
              end
            else
              if item |> String.contains?("b.") do
                item = item |> String.replace("b.", "")

                """
                |> where([a, b], ilike(b.#{item}, ^"%#{ss}%"))
                """
              else
                """
                |> where([a], ilike(a.#{item}, ^"%#{ss}%"))
                """
              end
              |> IO.inspect()
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
        |> Poison.decode!()
        |> IO.inspect()
        |> Enum.map(&(&1 |> convert_to_atom.()))

        # |> Enum.map(&(&1 |> String.to_atom()))
      end
      |> List.flatten()

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
      |> IO.inspect()
      |> Enum.filter(&(elem(Code.ensure_compiled(&1), 0) == :module))
      |> IO.inspect()
      |> List.first()

    IO.inspect(struct)

    json =
      BluePotion.post_process_datatable(
        params,
        struct,
        additional_join_statements,
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
