class CreateCommentsMigration < Dynomite::Migration
  def up
    create_table :comments do |t|
      t.partition_key "post_id:string" # required
      t.sort_key  "created_at:string" # optional
      t.provisioned_throughput(5) # sets both read and write, defaults to 5 when not set

      t.lsi do |i|
        i.partition_key "user_id:string"
        i.sort_key "updated_at:string" # optional

        i.provisioned_throughput(10)
      end
    end
  end
end

class UpdateCommentsMigration < Dynomite::Migration
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

