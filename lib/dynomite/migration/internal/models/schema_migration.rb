class SchemaMigration < Dynomite::Item
  disable_id!
  field :version, type: :integer
  field :time_took, type: :integer
  fields :status, :path, :error_message
end
