defmodule TwilixirBot.Repo.Migrations.AlterPassword do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :hashed_password, :string, null: true, from: {:string, null: false}
    end
  end
end
