class <%= @migration_class_name %> < Dynomite::Migration
  def up
    delete_table :<%= @table_name %>
  end
end

# More examples: https://rubyonjets.com/docs/database/dynamodb/migration/
