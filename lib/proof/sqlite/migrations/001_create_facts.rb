# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table(:facts) do
      primary_key :id
      column :run_id, String, null: false
      column :version, Integer, null: false
      column :kind, String, null: false
      column :at_seconds, Integer, null: false
      column :at_nanoseconds, Integer, null: false
      %i[position cpus megabytes exit_status signal bytes].each { |name| column(name, Integer) }
      %i[os labels host runner reason].each { |name| column(name, String) }
      index %i[run_id version], unique: true, name: :facts_one_fact_per_version
      index :position, unique: true, where: { kind: "Queued" }, name: :facts_one_run_per_position
      index :run_id, unique: true, where: { kind: "Placed" }, name: :facts_one_placement_per_run
    end
  end
end
