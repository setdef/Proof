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
      column :position, Integer
      column :os, String
      column :labels, String
      column :cpus, Integer
      column :megabytes, Integer
      column :host, String
      column :runner, String
      column :exit_status, Integer
      column :signal, Integer
      column :bytes, Integer
      column :reason, String
    end
  end
end
