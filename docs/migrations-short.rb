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
