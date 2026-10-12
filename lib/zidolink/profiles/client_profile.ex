defmodule Zidolink.Profiles.ClientProfile do
  use Ecto.Schema
  import Ecto.Changeset

  @genders ["male", "female", "other"]
  @activity_levels ["sedentary", "light", "moderate", "active", "very_active"]

  schema "client_profiles" do
    field :location_lat, :float
    field :location_lng, :float
    field :display_name, :string
    field :phone_visible_to_trainers, :boolean, default: true
    field :height_cm, :float
    field :age, :integer
    field :gender, :string
    field :activity_level, :string
    field :goal_text, :string
    field :target_weight_kg, :float

    belongs_to :user, Zidolink.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(client_profile, attrs) do
    client_profile
    |> cast(attrs, [
      :location_lat,
      :location_lng,
      :display_name,
      :phone_visible_to_trainers,
      :height_cm,
      :age,
      :gender,
      :activity_level,
      :goal_text,
      :target_weight_kg,
      :user_id
    ])
    |> validate_required([:user_id])
    |> validate_inclusion(:gender, @genders)
    |> validate_inclusion(:activity_level, @activity_levels)
    |> validate_number(:age, greater_than: 0, less_than: 120)
    |> validate_number(:height_cm, greater_than: 0)
    |> validate_number(:target_weight_kg, greater_than: 0)
    |> validate_goal_word_count()
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
  end

  defp validate_goal_word_count(changeset) do
    validate_change(changeset, :goal_text, fn :goal_text, value ->
      word_count = value |> String.split(~r/\s+/, trim: true) |> length()

      if word_count > 150 do
        [goal_text: "must be 150 words or fewer (currently #{word_count})"]
      else
        []
      end
    end)
  end
end
