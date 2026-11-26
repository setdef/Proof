# frozen_string_literal: true

ROM::SQL.migration do
  change do
    alter_table(:facts) do
      add_index(%i[run_id version], unique: true, name: :facts_one_fact_per_version)
      add_index(:position, unique: true, where: { kind: "Queued" }, name: :facts_one_run_per_position)
      add_index(:run_id, unique: true, where: { kind: "Placed" }, name: :facts_one_placement_per_run)
    end
  end
end
