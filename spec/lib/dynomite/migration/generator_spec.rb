require "spec_helper"

describe Dynomite::Migration::Generator do
  before(:each) do
    FileUtils.rm_rf("#{Dynomite.app_root}dynamodb/migrate")
  end

  let(:generator) do
    Dynomite::Migration::Generator.new("comments",
      partition_key: "post_id:string",
      sort_key: "created_at:string",
      quiet: true
    )
  end

  it "generates migration file in dynamodb/migrate" do
    generator.generate

    migration_path = Dir.glob("#{Dynomite.app_root}dynamodb/migrate/*").first
    migration_exist = File.exist?(migration_path)
    expect(migration_exist).to be true
  end
end
