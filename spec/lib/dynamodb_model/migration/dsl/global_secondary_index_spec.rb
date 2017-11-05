require "spec_helper"

GSI = DynamodbModel::Migration::Dsl::GlobalSecondaryIndex

describe GSI do
  let(:index) do
    DynamodbModel::Migration::Dsl.db = double("db").as_null_object
    GSI.new
  end

  # Supports this DSL, the `i` variable passed to the block is the
  # Dsl::GlobalSecondaryIndex instance
  #
  # class UpdateCommentsMigration < DynamodbModel::Migration
  #   def up
  #     update_table :comments do |t|
  #       t.partition_key "post_id:string" # required
  #       t.sort_key  "created_at:string" # optional
  #       t.provisioned_throughput(5) # sets both read and write
  #     end
  #   end
  # end
  it "build up the dsl in memory" do
    index.partition_key "id:string" # required
    index.sort_key  "created_at:string" # optional
    index.provisioned_throughput(30)

    expect(index.key_schema).to eq([
      {:attribute_name=>"id", :key_type=>"HASH"},
      {:attribute_name=>"created_at", :key_type=>"RANGE"}])
    expect(index.attribute_definitions).to eq([
      {:attribute_name=>"id", :attribute_type=>"S"},
      {:attribute_name=>"created_at", :attribute_type=>"S"}])
    expect(index.provisioned_throughput).to eq(
      :read_capacity_units=>30,
      :write_capacity_units=>30
    )
  end

  it "execute uses what the dsl methods built up in memory and translates it dynmaodb params that then get used to execute and run the command" do
    index.partition_key "id:string" # required
    index.sort_key  "created_at:string" # optional
    index.provisioned_throughput(30)
    # index.execute # TODO: index.execute in here
  end
end

