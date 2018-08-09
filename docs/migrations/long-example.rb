# Note: table name created will be namespaced based on
# Dynomite::Migration.table_namespace.  This can be set in
# config/dynamodb.yml
#
# development:
#   table_namespace: "mynamespace"
#
# This results in:
#   create_table "posts"
# Produces:
#   table name: "mynamespace-posts"
#
# When you're in a in Jets project you can set the namespace based on
# Jets.config.table_namespace, which is based on the project name and
# a short version of the environment.  Example:
#
# `config/dynamodb.yml`:
# development:
#   table_namespace: <%= Jets.config.table_namespace %>
#
# If your project_name is demo and environment is production:
#   create_table "posts" => table name: "demo-prod-posts"
#
# If your project_name is proj and environment is staging:
#   create_table "posts" => table name: "demo-stag-posts"
#
# If your project_name is proj and environment is development:
#   create_table "posts" => table name: "demo-dev-posts"
#
# If the table_namespace is set to a blank string or nil, then a namespace
# will not be prepended at all.

class CreateCommentsMigration < Dynomite::Migration
  def up
    create_table :comments do |t|
      t.partition_key "post_id:string" # required
      t.sort_key  "created_at:string" # optional
      t.provisioned_throughput(5) # sets both read and write, defaults to 5 when not set

      # Instead of using partition_key and sort_key you can set the
      # key schema directly also
      # t.key_schema([
      #     {attribute_name: "id", :key_type=>"HASH"},
      #     {attribute_name: "created_at", :key_type=>"RANGE"}
      #   ])
      # t.attribute_definitions([
      #   {attribute_name: "id", attribute_type: "N"},
      #   {attribute_name: "created_at", attribute_type: "S"}
      # ])

      # other ways to set provisioned_throughput
      # t.provisioned_throughput(:read, 10)
      # t.provisioned_throughput(:write, 10)
      # t.provisioned_throughput(
      #   read_capacity_units: 5,
      #   write_capacity_units: 5
      # )
    end
  end
end

class UpdateCommentsMigration < Dynomite::Migration
  def up
    update_table :comments do |t|

      # t.global_secondary_index do
      # t.gsi(METHOD, INDEX_NAME) do

      # You normally create an index like so:
      #
      #  t.gsi(:create) do |i|
      #    i.partition_key = "post_id:string" # partition_key is required
      #    i.sort_key = "updated_at:string" # sort_key is optional
      #  end
      #
      # The index name will be inferred from the partition_key and sort_key when
      # not explicitly set.  Examples:
      #
      #   index_name = "#{partition_key}-#{sort_key}-index"
      #   index_name = "post_id-index" # no sort key
      #   index_name = "post_id-updated_at-index" # has sort key
      #
      # The inference allows you to not have to worry about the index
      # naming scheme. You can still set the index_name explicitly like so:
      #
      #  t.gsi(:create, "post_id-updated_at-index") do |i|
      #    i.partition_key = "post_id:string" # partition_key is required
      #    i.sort_key = "updated_at:string" # sort_key is optional
      #  end
      #
      t.gsi(:create) do |i|
        i.partition_key "post_id:string"
        i.sort_key "updated_at:string" # optional

        # translates to
        # i.key_schema({...})
        # also makes sure that the schema_keys are added to the attributes_definitions

        # t.projected_attributes(:all) # default if not called
        # t.projected_attributes(:keys_only) # other ways to call
        # t.projected_attributes([:id, :body, :tags, :updated_at])
        # translates to:
        # Valid Values: ALL | KEYS_ONLY | INCLUDE
        # t.projection(
        #   projection_type: :all, # defaults to all
        # )
        # t.projection(
        #   projection_type: :include, # defaults to all
        #   non_key_attributes: [:id, :body, :tags, :updated_at], # defaults to all
        # )

        i.provisioned_throughput(10)
      end

      t.gsi(:update, "category-index") do |i|
        i.provisioned_throughput(10)
      end

      t.gsi(:delete, "category-index")
    end
  end
end

