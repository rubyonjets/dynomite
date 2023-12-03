class CreateSchemaMigrations < Dynomite::Migration
  include Dynomite::Client

  def up
    create_table :schema_migrations do |t|
      t.partition_key "version:number" # required
      t.billing_mode "PAY_PER_REQUEST"
    end
  end

  def table_exist?(full_table_name)
    client.describe_table(table_name: full_table_name)
    true
  rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    false
  end
end
