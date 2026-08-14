defmodule Zidolink.RoleApplications do
  @moduledoc """
  The RoleApplications context — trainer/seller applications and admin review.
  """

  import Ecto.Query, warn: false
  alias Zidolink.Repo
  alias Zidolink.RoleApplications.RoleApplication

  def get_latest_application(user_id) do
    RoleApplication
    |> where([a], a.user_id == ^user_id)
    |> order_by([a], desc: a.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def get_by_invoice_id(invoice_id) do
    Repo.get_by(RoleApplication, invoice_id: invoice_id)
  end

  def create_application(attrs) do
    %RoleApplication{}
    |> RoleApplication.changeset(attrs)
    |> Repo.insert()
  end

  def update_application(%RoleApplication{} = application, attrs) do
    application
    |> RoleApplication.changeset(attrs)
    |> Repo.update()
  end

  def list_pending_applications do
    Repo.all(
      from a in RoleApplication,
        where: a.status == "pending_review" and a.payment_status == "complete",
        order_by: [asc: a.inserted_at]
    )
  end
end
