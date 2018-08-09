require "spec_helper"

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
  context "mocked db" do
    before(:each) { Dynomite::Migration::Dsl.db = db }
    let(:db) { double(:db) }
    let(:null) { double(:null).as_null_object }

    it "executes the migration" do
      allow(db).to receive(:create_table).and_return(null)

      CreateCommentsMigration.new.up

      expect(db).to have_received(:create_table)
    end
  end

  # To test dynamodb endpoint configured in config/dynamodb.yml uncomment the code
  # you want to test and run:
  #
  #   LIVE=1 rspec spec/lib/dynomite/migration_spec.rb -e 'live db'
  #
  context "live db" do
    before(:each) { Dynomite::Item.db = nil } # setting to nil will clear out mock and force it to load AWS
    it "executes the migration" do
      CreateCommentsMigration.new.up # uncomment to test
      # UpdateCommentsMigration.new.up # uncomment to test
    end
  end if ENV['LIVE']
end

