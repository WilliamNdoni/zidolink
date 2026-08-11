defmodule Zidolink.Repo do
  use Ecto.Repo,
    otp_app: :zidolink,
    adapter: Ecto.Adapters.Postgres
end
