defmodule Zidolink.PlatformSettings do
  @moduledoc """
  The PlatformSettings context — a single, admin-editable row of platform-wide fees.
  """

  alias Zidolink.Repo
  alias Zidolink.PlatformSettings.PlatformSetting

  @doc """
  Returns the one settings row, creating it with defaults if it doesn't exist yet.
  """
  def get_settings do
    case Repo.one(PlatformSetting) do
      nil ->
        {:ok, setting} =
          %PlatformSetting{}
          |> PlatformSetting.changeset(%{
            signup_fee: 5000,
            platform_markup_fee: 100,
            refund_deduction_fee: 500
          })
          |> Repo.insert()

        setting

      setting ->
        setting
    end
  end

  def update_settings(attrs) do
    get_settings()
    |> PlatformSetting.changeset(attrs)
    |> Repo.update()
  end
end
