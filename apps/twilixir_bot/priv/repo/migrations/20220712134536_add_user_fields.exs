defmodule TwilixirBot.Repo.Migrations.AddUserFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :external_id, :string, null: false
      add :external_id_source, :string, null: false
      add :display_name, :string, null: false
    end
  end
end
