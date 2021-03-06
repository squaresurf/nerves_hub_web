defmodule NervesHubWWWWeb.AccountController do
  use NervesHubWWWWeb, :controller

  alias Ecto.Changeset
  alias NervesHubCore.Accounts
  alias NervesHubCore.Accounts.User

  plug(NervesHubWWWWeb.Plugs.AllowUninvitedSignups when action in [:new, :create])

  def new(conn, _params) do
    render(conn, "new.html", changeset: %Changeset{data: %User{}})
  end

  defp whitelist(params, keys) do
    keys
    |> Enum.filter(fn x -> !is_nil(params[to_string(x)]) end)
    |> Enum.into(%{}, fn x -> {x, params[to_string(x)]} end)
  end

  def create(conn, %{"user" => user_params}) do
    user_params
    |> whitelist([:password, :name, :email])
    |> Map.put(:orgs, [%{name: user_params["name"]}])
    |> Accounts.create_user()
    |> case do
      {:ok, _user} ->
        redirect(conn, to: "/")

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, _params) do
    conn
    |> render(
      "edit.html",
      changeset: %Changeset{data: conn.assigns.user}
    )
  end

  def update(conn, params) do
    cleaned =
      params["user"]
      |> whitelist([:current_password, :password, :name, :email, :orgs])

    conn.assigns.user
    |> Accounts.update_user(cleaned)
    |> case do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Account updated")
        |> redirect(to: account_path(conn, :edit))

      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end

  def invite(conn, %{"token" => token} = _) do
    with {:ok, invite} <- Accounts.get_valid_invite(token),
         {:ok, org} <- Accounts.get_org(invite.org_id) do
      render(
        conn,
        "invite.html",
        changeset: %Changeset{data: invite},
        org: org,
        token: token
      )
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid or expired invite")
        |> redirect(to: "/")
    end
  end

  def accept_invite(conn, %{"user" => user_params, "token" => token} = _) do
    clean_params = user_params |> whitelist([:password])

    with {:ok, invite} <- Accounts.get_valid_invite(token),
         {:ok, org} <- Accounts.get_org(invite.org_id),
         {:ok, _user} <- Accounts.create_user_from_invite(invite, org, clean_params) do
      conn
      |> put_flash(:info, "Account successfully created, login below")
      |> redirect(to: "/")
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid or expired invite")
        |> redirect(to: "/")
    end
  end
end
