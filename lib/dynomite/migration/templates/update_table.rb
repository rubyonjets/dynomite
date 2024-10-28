class <%= @migration_class_name %> < Dynomite::Migration
  def up
    update_table :<%= @table_name %> do |t|
      t.add_gsi(partition_key: "<%= @partition_key %>", sort_key: "<%= @sort_key || 'updated_at' %>")

      # t.remove_gsi(partition_key: "<%= @partition_key %>", sort_key: "<%= @sort_key || 'updated_at' %>")
    end
  end
end

# More examples: https://v5.docs.rubyonjets.com/docs/database/dynamodb/migration/
