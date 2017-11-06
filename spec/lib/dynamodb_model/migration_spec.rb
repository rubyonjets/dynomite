require "spec_helper"

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
      t.provisioned_throughput(7) # sets both read and write, defaults to 5 when not set
      t.gsi(:create) do |i|
        i.partition_key "post_id:string"
        i.sort_key "updated_at:string" # optional
        i.provisioned_throughput(8)
      end
      t.gsi(:update, "update-me-index") do |i|
        i.provisioned_throughput(9)
      end
      t.gsi(:delete, "delete-me-index")
    end
  end
end

describe DynamodbModel::Migration do
  context "mocked db" do
    before(:each) { DynamodbModel::Migration::Dsl.db = db }
    let(:db) { double(:db) }
    let(:null) { double(:null).as_null_object }

    it "executes the migration" do
      allow(db).to receive(:create_table).and_return(null)

      CreateCommentsMigration.new.up

      expect(db).to have_received(:create_table)
    end
  end

  # To test dynamodb endpoint configured in config/dynamodb.yml run:
  #
  #   LIVE=1 rspec spec/lib/dynamodb_model/migration_spec.rb -e 'live db'
  context "live db" do
    before(:each) { DynamodbModel::Item.db = nil } # setting to nil will clear out mock and force it to load AWS
    it "executes the migration" do
      CommentsMigration.new.up
    end
  end if ENV['LIVE']
end

