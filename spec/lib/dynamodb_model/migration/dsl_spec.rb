require "spec_helper"

describe DynamodbModel::Migration::Dsl do
  let(:dsl) do
    DynamodbModel::Migration::Dsl.db = double("db").as_null_object
    DynamodbModel::Migration::Dsl.new("posts")
  end

  it "build up the dsl in memory" do

    dsl.partition_key "id:string" # required
    dsl.sort_key  "created_at:string" # optional
    dsl.provisioned_throughput(25)

    expect(dsl.key_schema).to eq([
      {:attribute_name=>"id", :key_type=>"HASH"},
      {:attribute_name=>"created_at", :key_type=>"RANGE"}])
    expect(dsl.attribute_definitions).to eq([
      {:attribute_name=>"id", :attribute_type=>"S"},
      {:attribute_name=>"created_at", :attribute_type=>"S"}])
    expect(dsl.provisioned_throughput).to eq(
      :read_capacity_units=>25,
      :write_capacity_units=>25
    )
  end

  it "executing dsl creates the table" do
    dsl.partition_key "id:string" # required
    dsl.sort_key  "created_at:string" # optional
    dsl.provisioned_throughput(25)
    dsl.execute
  end
end

