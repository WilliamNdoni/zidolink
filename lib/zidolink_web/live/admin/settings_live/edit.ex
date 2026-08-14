defmodule ZidolinkWeb.Admin.SettingsLive.Edit do
  use ZidolinkWeb, :live_view

  alias Zidolink.PlatformSettings

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md">
        <.header>Platform fees</.header>

        <.form for={@form} id="settings_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:signup_fee]}
            type="number"
            label="Trainer/seller signup fee (KES)"
            required
          />
          <.input
            field={@form[:platform_markup_fee]}
            type="number"
            label="Platform markup added to client-facing prices (KES)"
            required
          />
          <.input
            field={@form[:refund_deduction_fee]}
            type="number"
            label="Non-refundable deduction on rejected applications (KES)"
            required
          />

          <.button phx-disable-with="Saving..." class="btn btn-primary w-full mt-4">
            Save
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    settings = PlatformSettings.get_settings()
    changeset = Zidolink.PlatformSettings.PlatformSetting.changeset(settings, %{})
    {:ok, assign(socket, form: to_form(changeset), settings: settings)}
  end

  @impl true
  def handle_event("validate", %{"platform_setting" => params}, socket) do
    changeset =
      socket.assigns.settings
      |> Zidolink.PlatformSettings.PlatformSetting.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"platform_setting" => params}, socket) do
    case PlatformSettings.update_settings(params) do
      {:ok, settings} ->
        {:noreply,
         socket
         |> put_flash(:info, "Settings saved.")
         |> assign(settings: settings, form: to_form(Zidolink.PlatformSettings.PlatformSetting.changeset(settings, %{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
