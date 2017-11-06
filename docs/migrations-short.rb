class UpdateCommentsMigration < DynamodbModel::Migration
  def up
    update_table :comments do |t|
      t.gsi(:create) do |i|
        i.partition_key "post_id:string"
        i.sort_key "updated_at:string" # optional
      end
    end
  end
end

class UpdateCommentsMigration < DynamodbModel::Migration
  def up
    update_table :comments do |t|
      t.gsi(:create) do |i|
        i.partition_key "post_id:string"
        i.sort_key "updated_at:string" # optional

        i.provisioned_throughput(10)
      end

      t.gsi(:update, "update-me-index") do |i|
        i.provisioned_throughput(10)
      end

      t.gsi(:delete, "delete-me-index")
    end
  end
end

