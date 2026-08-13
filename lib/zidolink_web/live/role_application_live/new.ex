defmodule ZidolinkWeb.RoleApplicationLive.New do
  use ZidolinkWeb, :live_view

  alias Zidolink.RoleApplications

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg">
        <%= cond do %>
          <% is_nil(@role) -> %>
            <div class="text-center">
              <.header>Nothing to apply for</.header>
              <p class="mt-4">You don't currently have a pending trainer or seller application.</p>
            </div>
          <% @existing_application -> %>
            <div class="text-center">
              <.header>Application under review</.header>
              <p class="mt-4">
                Your {@role} application was submitted and is being reviewed. We'll be in touch by email once there's a decision.
              </p>
            </div>
          <% true -> %>
            <div class="text-center">
              <.header>
                Apply as a {String.capitalize(@role)}
                <:subtitle>
                  Tell us a bit about yourself so we can review your application.
                </:subtitle>
              </.header>
            </div>

            <.form for={@form} id="application_form" phx-submit="save" phx-change="validate">
              <%= if @role == "trainer" do %>
                <.input field={@form[:bio]} type="textarea" label="Bio" required />
                <.input
                  field={@form[:social_url]}
                  type="text"
                  label="Instagram / TikTok / social profile link"
                  required
                />
                <.input
                  field={@form[:certification]}
                  type="text"
                  label="Certification (optional, e.g. ACE, ISSA, NASM)"
                />
                <.input
                  field={@form[:gym_affiliation]}
                  type="text"
                  label="Gym or studio you train at (optional)"
                />
              <% end %>

              <%= if @role == "seller" do %>
                <.input field={@form[:shop_name]} type="text" label="Shop name" required />
                <.input
                  field={@form[:category]}
                  type="select"
                  label="Category"
                  options={[
                    {"Nutrition", "nutrition"},
                    {"Gym equipment", "equipment"},
                    {"Gym wear", "wear"}
                  ]}
                  required
                />
                <.input
                  field={@form[:social_url]}
                  type="text"
                  label="Instagram / TikTok / social profile link"
                  required
                />
                <.input
                  field={@form[:sample_products]}
                  type="textarea"
                  label="List a few products you plan to sell"
                  required
                />
              <% end %>

              <.button phx-disable-with="Submitting..." class="btn btn-primary w-full mt-4">
                Submit application
              </.button>
            </.form>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    role = user.pending_role_request
    existing_application = role && RoleApplications.get_latest_application(user.id)

    form = to_form(%{}, as: "application")

    {:ok,
     assign(socket,
       role: role,
       existing_application: existing_application,
       form: form
     )}
  end

  @impl true
  def handle_event("validate", %{"application" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "application"))}
  end

  def handle_event("save", %{"application" => params}, socket) do
    user = socket.assigns.current_scope.user

    case RoleApplications.create_application(%{
           user_id: user.id,
           role: socket.assigns.role,
           data: params
         }) do
      {:ok, application} ->
        {:noreply, assign(socket, existing_application: application)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Something went wrong — please check the form and try again.")
         |> assign(form: to_form(changeset, as: "application"))}
    end
  end
end
