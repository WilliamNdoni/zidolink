defmodule ZidolinkWeb.UserLive.Registration do
  use ZidolinkWeb, :live_view

  alias Zidolink.Accounts
  alias Zidolink.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Register for an account
            <:subtitle>
              Already registered?
              <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
                Log in
              </.link>
              to your account now.
            </:subtitle>
          </.header>
        </div>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />

          <.input
            field={@form[:phone]}
            type="text"
            label="Phone (Safaricom, e.g. 2547XXXXXXXX)"
            autocomplete="tel"
            spellcheck="false"
            required
          />

          <fieldset class="fieldset mt-2">
            <legend class="fieldset-legend">Join as</legend>
            <label class="label cursor-pointer justify-start gap-2">
              <input type="radio" name="user[join_as]" value="client" class="radio radio-sm" checked={@form[:join_as].value in [nil, "client"]} />
              <span>Client — find and train with a trainer</span>
            </label>
            <label class="label cursor-pointer justify-start gap-2">
              <input type="radio" name="user[join_as]" value="trainer" class="radio radio-sm" checked={@form[:join_as].value == "trainer"} />
              <span>Trainer — manage clients and sell your expertise</span>
            </label>
            <label class="label cursor-pointer justify-start gap-2">
              <input type="radio" name="user[join_as]" value="seller" class="radio radio-sm" checked={@form[:join_as].value == "seller"} />
              <span>Seller — sell products, gear, or ebooks</span>
            </label>
          </fieldset>

          <.button phx-disable-with="Creating account..." class="btn btn-primary w-full mt-4">
            Create an account
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: ZidolinkWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        message =
          if user.pending_role_request do
            "An email was sent to #{user.email}, please confirm your account. Your #{user.pending_role_request} application will be reviewed once you're set up — we'll be in touch."
          else
            "An email was sent to #{user.email}, please access it to confirm your account."
          end

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
