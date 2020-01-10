class SchemaMigration < Dynomite::Item
  table_name :schema_migrations
  partition_key :version
  field :status, :time_took, :path
end
