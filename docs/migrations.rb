class CreateCommentsMigration < DynamodbModel::Migration
  def up
    create_table :comments do |t|
      t.partition_key "post_id:string" # required
      t.sort_key  "created_at:string" # optional
      t.provisioned_throughput(5) # sets both read and write, defaults to 5 when not set
    end
  end
end

class UpdateCommentsMigration < DynamodbModel::Migration
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

