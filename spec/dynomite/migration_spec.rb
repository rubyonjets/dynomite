class CreateCommentsMigration < Dynomite::Migration
  def up
    create_table :comments do |t|
      t.partition_key "post_id:string" # required
      t.sort_key  "created_at:string" # optional
      t.provisioned_throughput(5) # sets both read and write, defaults to 5 when not set
    end
  end
end

class UpdateCommentsMigration < Dynomite::Migration
  def up
    update_table :comments do |t|
      # NOTE: You cannot update provisioned_throughput at the same time as creating
      # an GSI
      # t.provisioned_throughput(7) # sets both read and write, defaults to 5 when not set
      t.gsi(:create) do |i|
        i.partition_key "post_id:string"
        i.sort_key "updated_at:string" # optional
        i.provisioned_throughput(8)
      end
      # t.gsi(:update, "update-me-index") do |i|
      #   i.provisioned_throughput(9)
      # end
      # t.gsi(:delete, "delete-me-index")
    end
  end
end

describe Dynomite::Migration do
  context "mocked client" do
    let(:null) { double(:null).as_null_object }

    it "executes the migration" do
      migration = CreateCommentsMigration.new
      allow(migration).to receive(:create_table).and_return(null)
      allow(migration).to receive(:waiter).and_return(null)

      migration.up

      expect(migration).to have_received(:create_table)
    end
  end
end
