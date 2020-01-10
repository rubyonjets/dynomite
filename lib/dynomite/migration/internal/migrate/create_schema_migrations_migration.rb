class CreateSchemaMigrationsMigration < Dynomite::Migration
  include Dynomite::Client

  def up
    create_table :schema_migrations do |t|
      t.partition_key "version:string" # required
      t.billing_mode "PAY_PER_REQUEST"
    end
  end

  def table_exist?(full_table_name)
    db.describe_table(table_name: full_table_name)
    true
  rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    false
  end
end
