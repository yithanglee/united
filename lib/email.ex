defmodule United.Mailer do
  use Bamboo.Mailer, otp_app: :united
end

defmodule United.Email do
  import Bamboo.Email
  import Bamboo.Phoenix

  use Bamboo.Phoenix, view: UnitedWeb.EmailView

  def custom_email(user_email, subject, html) do
    # Build your default email then customize for welcome
    base_email()
    |> to(user_email)
    |> subject("Ark Library - #{subject}")
    |> put_header("Reply-To", "library@kajangcmc.org")
    |> render("custom_email.html", html: html)
  end

  def remind_email(user_email, member, books) do
    # Build your default email then customize for welcome
    base_email()
    |> to(user_email)
    |> subject("Ark Library - Loan return reminder")
    |> put_header("Reply-To", "library@kajangcmc.org")
    |> render("loan_reminder.html", member: member, books: books)
  end

  def _reset_email(user_email, user) do
    # Build your default email then customize for welcome
    base_email()
    |> to(user_email)
    |> subject("Password reset request")
    |> put_header("Reply-To", "library@kajangcmc.org")
    |> render("forget_password.html", user: user)
  end

  def notification_email(customer_email, book, visitor) do
    # Build your default email then customize for welcome
    base_email()
    |> to(customer_email)
    |> subject("Welcome")
    |> put_header("Reply-To", "library@kajangcmc.org")
    |> render("notify.html", book: book, visitor: visitor)
  end

  def reservation_email(customer_email, book, visitor) do
    # Build your default email then customize for welcome
    base_email()
    |> to(customer_email)
    |> subject("Ark Library - Book reserved")
    |> put_header("Reply-To", "library@kajangcmc.org")
    |> render("reserve.html", book: book, member: visitor)
  end

  def available_email(customer_email, book, visitor) do
    # Build your default email then customize for welcome
    base_email()
    |> to(customer_email)
    |> subject("Ark Library - Book available")
    |> put_header("Reply-To", "library@kajangcmc.org")
    |> render("available.html", book: book, member: visitor)
  end

  def _shipped_email(customer_email, cart, visitor) do
    # Build your default email then customize for welcome
    base_email()
    |> to(customer_email)
    |> subject("Welcome!!!")
    |> put_header("Reply-To", "library@kajangcmc.org")
    |> render("shipped.html", cart: cart, visitor: visitor)
  end

  defp base_email do
    new_email()
    # Set a default from
    |> from("library@kajangcmc.org")
    # Set default layout
    |> put_html_layout({UnitedWeb.LayoutView, "email.html"})

    # Set default text layout
    # |> put_text_layout({UnitedWeb.LayoutView, "email.text"})
  end
end

# United.Email.welcome_email |> United.Mailer.deliver_now
