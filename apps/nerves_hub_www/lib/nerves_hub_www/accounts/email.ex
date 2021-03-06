defmodule NervesHubWWW.Accounts.Email do
  use Bamboo.Phoenix, view: NervesHubWWWWeb.EmailView

  alias NervesHubCore.Accounts.{Invite, Org, User}

  @from {"NervesHub", "no-reply@nerves-hub.org"}

  def invite(%Invite{} = invite, %Org{} = org) do
    new_email()
    |> from(@from)
    |> to(invite.email)
    |> subject("Welcome to NervesHub!")
    |> put_layout({NervesHubWWWWeb.LayoutView, :email})
    |> render("invite.html", invite: invite, org: org)
  end

  def forgot_password(%User{email: email, password_reset_token: token} = user)
      when is_binary(token) do
    new_email()
    |> from(@from)
    |> to(email)
    |> subject("Reset NervesHub Password")
    |> put_layout({NervesHubWWWWeb.LayoutView, :email})
    |> render("forgot_password.html", user: user)
  end
end
