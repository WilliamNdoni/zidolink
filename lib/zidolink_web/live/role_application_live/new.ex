defmodule ZidolinkWeb.RoleApplicationLive.New do
  use ZidolinkWeb, :live_view

  alias Zidolink.RoleApplications
  alias Zidolink.Payments.Intasend

  @poll_interval 3_000
  @poll_timeout_ms 90_000

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
          <% @existing_application && @existing_application.payment_status == "complete" -> %>
            <div class="text-center">
              <.header>Application under review</.header>
              <p class="mt-4">
                Your {@role} application was submitted and is being reviewed. We'll be in touch by email once there's a decision.
              </p>
            </div>
          <% @existing_application && @existing_application.payment_status in ["awaiting_payment", "expired"] -> %>
            <div class="text-center">
              <.header>Check your phone</.header>
              <p class="mt-4">
                We've sent an M-Pesa prompt to confirm your KES {@signup_fee} application fee. Enter your PIN to continue.
              </p>
              <div :if={!@poll_timed_out} class="mt-6">
                <span class="loading loading-spinner loading-md"></span>
              </div>
              <p :if={@poll_timed_out} class="mt-6 text-error">
                We didn't receive confirmation — this sometimes happens. You can try again.
              </p>
              <.button :if={@poll_timed_out} phx-click="retry_payment" class="btn btn-primary mt-4">
                Try again
              </.button>
            </div>
          <% true -> %>
            <div class="text-center">
              <.header>
                Apply as a {String.capitalize(@role)}
                <:subtitle>
                  Tell us a bit about yourself. A KES {@signup_fee} application fee applies once you submit &mdash; refundable minus a {@refund_deduction_fee} KES processing fee if not approved.
                </:subtitle>
              </.header>
            </div>

            <.form for={@form} id="application_form" phx-submit="save" phx-change="validate">
              <.input
                field={@form[:full_legal_name]}
                type="text"
                label="Full legal name"
                required
              />
              <p class="text-sm text-base-content/60 -mt-2 mb-3">
                For verification only — never shown publicly.
              </p>

              <%= if @role == "trainer" do %>
                <.input
                  field={@form[:display_name]}
                  type="text"
                  label="Display name (optional)"
                />
                <p class="text-sm text-base-content/60 -mt-2 mb-3">
                  What clients will see on your profile — your name or a business name. Leave blank to use your legal name.
                </p>

                <.input field={@form[:bio]} type="textarea" label="Bio" required />

                <.input
                  field={@form[:social_platform]}
                  type="select"
                  label="Social media platform"
                  options={[
                    {"Instagram", "instagram"},
                    {"TikTok", "tiktok"},
                    {"Facebook", "facebook"},
                    {"YouTube", "youtube"}
                  ]}
                  required
                />
                <.input
                  field={@form[:social_username]}
                  type="text"
                  label="Username"
                  required
                />

                <div class="mt-2">
                  <label class="label">Certification</label>
                  <p class="text-sm text-base-content/60 mb-2">
                    Upload a photo or PDF of your certification, if you have one (optional).
                  </p>
                  <.live_file_input
                    upload={@uploads.certificate}
                    class="file-input file-input-bordered w-full"
                  />
                  <div :for={entry <- @uploads.certificate.entries} class="mt-2 text-sm flex items-center gap-2">
                    <.icon name="hero-document" class="size-4" />
                    {entry.client_name}
                    <progress class="progress progress-primary w-24" value={entry.progress} max="100"></progress>
                    <button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      class="text-error"
                    >
                      &times;
                    </button>
                  </div>
                  <p :for={err <- upload_errors(@uploads.certificate)} class="text-error text-sm mt-1">
                    {error_to_string(err)}
                  </p>
                </div>
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
                  field={@form[:social_platform]}
                  type="select"
                  label="Social media platform"
                  options={[
                    {"Instagram", "instagram"},
                    {"TikTok", "tiktok"},
                    {"Facebook", "facebook"},
                    {"YouTube", "youtube"},
                    {"WhatsApp Business", "whatsapp_business"}
                  ]}
                  required
                />
                <p class="text-sm text-base-content/60 -mt-2 mb-3">
                  Only use WhatsApp Business if you don't have Instagram, TikTok, Facebook, or YouTube for your shop.
                </p>
                <.input
                  field={@form[:social_username]}
                  type="text"
                  label={if @form[:social_platform].value == "whatsapp_business", do: "WhatsApp Business number", else: "Username"}
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
                Submit application &amp; pay KES {@signup_fee}
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
    settings = Zidolink.PlatformSettings.get_settings()
    role = user.pending_role_request
    existing_application = role && RoleApplications.get_latest_application(user.id)

    form = to_form(%{}, as: "application")

    socket =
      allow_upload(socket, :certificate,
        accept: ~w(.jpg .jpeg .png .pdf),
        max_entries: 1,
        max_file_size: 10_000_000,
        auto_upload: false
      )

    {poll_timed_out, poll_deadline} =
      case existing_application do
        %{payment_status: "awaiting_payment"} ->
          deadline = DateTime.add(DateTime.utc_now(), @poll_timeout_ms, :millisecond)
          if connected?(socket), do: schedule_poll()
          {false, deadline}

        %{payment_status: "expired"} ->
          {true, nil}

        _ ->
          {false, nil}
      end

    {:ok,
     assign(socket,
       role: role,
       existing_application: existing_application,
       form: form,
       poll_timed_out: poll_timed_out,
       poll_deadline: poll_deadline,
       signup_fee: settings.signup_fee,
       refund_deduction_fee: settings.refund_deduction_fee
     )}
  end

  @impl true
  def handle_event("validate", %{"application" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "application"))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :certificate, ref)}
  end

  def handle_event("save", %{"application" => params}, socket) do
    user = socket.assigns.current_scope.user

    certificate_urls =
      consume_uploaded_entries(socket, :certificate, fn %{path: path}, entry ->
        case Zidolink.Media.Cloudinary.upload(path, entry.client_name) do
          {:ok, %{"secure_url" => url}} -> {:ok, url}
          {:error, _reason} -> {:ok, nil}
        end
      end)

    params =
      case certificate_urls do
        [url] when is_binary(url) -> Map.put(params, "certificate_url", url)
        _ -> params
      end

    case RoleApplications.create_application(%{
           user_id: user.id,
           role: socket.assigns.role,
           data: params,
           payment_status: "awaiting_payment"
         }) do
      {:ok, application} ->
        {:noreply, trigger_payment(socket, application, user)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Something went wrong — please check the form and try again.")
         |> assign(form: to_form(changeset, as: "application"))}
    end
  end

  def handle_event("retry_payment", _params, socket) do
    user = socket.assigns.current_scope.user
    application = socket.assigns.existing_application

    {:noreply,
     socket
     |> assign(poll_timed_out: false)
     |> trigger_payment(application, user)}
  end

  @impl true
  def handle_info(:poll_payment_status, socket) do
    application = socket.assigns.existing_application

    cond do
      is_nil(application) or is_nil(application.invoice_id) ->
        {:noreply, socket}

      DateTime.compare(DateTime.utc_now(), socket.assigns.poll_deadline) == :gt ->
        {:ok, updated} = RoleApplications.update_application(application, %{payment_status: "expired"})
        {:noreply, assign(socket, existing_application: updated, poll_timed_out: true)}

      true ->
        case Intasend.check_status(application.invoice_id) do
          {:ok, %{"invoice" => %{"state" => "COMPLETE"}}} ->
            {:ok, updated} =
              RoleApplications.update_application(application, %{payment_status: "complete"})

            {:noreply, assign(socket, existing_application: updated)}

          {:ok, %{"invoice" => %{"state" => "FAILED"}}} ->
            {:ok, updated} =
              RoleApplications.update_application(application, %{payment_status: "expired"})

            {:noreply, assign(socket, existing_application: updated, poll_timed_out: true)}

          _ ->
            schedule_poll()
            {:noreply, socket}
        end
    end
  end

  defp trigger_payment(socket, application, user) do
    api_ref = "application-#{application.id}"

    case Intasend.stk_push(user.phone, socket.assigns.signup_fee, api_ref) do
      {:ok, %{"invoice" => %{"invoice_id" => invoice_id}}} ->
        {:ok, updated} =
          RoleApplications.update_application(application, %{
            invoice_id: invoice_id,
            amount_paid: socket.assigns.signup_fee
          })

        deadline = DateTime.add(DateTime.utc_now(), @poll_timeout_ms, :millisecond)
        schedule_poll()

        socket
        |> assign(existing_application: updated, poll_deadline: deadline)

      {:error, _reason} ->
        put_flash(
          socket,
          :error,
          "We couldn't start the payment request — please try again."
        )
    end
  end

  defp schedule_poll do
    Process.send_after(self(), :poll_payment_status, @poll_interval)
  end

  defp error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp error_to_string(:not_accepted), do: "Only images and PDFs are accepted"
  defp error_to_string(:too_many_files), do: "Only one file allowed"

end
