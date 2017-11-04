require "spec_helper"

describe DynamodbModel::Migration::Generator do
  before(:each) do
    FileUtils.rm_rf("#{DynamodbModel.root}db/migrate")
  end

  let(:generator) do
    DynamodbModel::Migration::Generator.new("comments",
      partition_key: "post_id:string",
      sort_key: "created_at:string",
      quiet: true
    )
  end

  it "generates migration file in db/migrate" do
    generator.generate

    migration_path = Dir.glob("#{DynamodbModel.root}db/migrate/*").first
    migration_exist = File.exist?(migration_path)
    expect(migration_exist).to be true
  end
end
