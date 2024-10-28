class <%= @migration_class_name %> < Dynomite::Migration
  def up
    create_table :<%= @table_name %> do |t|
      t.partition_key :<%= @partition_key %>
<% if @sort_key # so extra spaces are not added when generated -%>
      t.sort_key  "<%= @sort_key %>" # optional
<% end -%>
<% if %w[id id:string].include?(@partition_key) -%>
      t.add_gsi :updated_at
<% else %>
      t.add_gsi :id
<% end -%>
    end
  end
end

# More examples: https://v5.docs.rubyonjets.com/docs/database/dynamodb/migration/
