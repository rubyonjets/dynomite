require "spec_helper"

describe DynamodbModel::Migration::Dsl do
  # Supports this DSL, the `t` variable passed to the block is the Dsl instance
  #
  # class CreateCommentsMigration < DynamodbModel::Migration
  #   def up
  #     create_table :comments do |t|
  #       t.partition_key "post_id:string" # required
  #       t.sort_key  "created_at:string" # optional
  #       t.provisioned_throughput(5) # sets both read and write, defaults to 5 when not set
  #     end
  #   end
  # end
  context "create_table" do
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
  end

  context "update_table" do
    let(:dsl) do
      DynamodbModel::Migration::Dsl.db = double("db").as_null_object
      DynamodbModel::Migration::Dsl.new("comments")
    end

    it "builds up the gsi index params also" do
      dsl.gsi(:create) do |i|
        i.partition_key "post_id:string"
        i.sort_key "updated_at:string" # optional
      end

      pp dsl.instance_variable_get(:@gsi_index)
    end
  end

  # it "execute uses what the dsl methods built up in memory and translates it dynmaodb params that then get used to execute and run the command" do
  #   dsl.partition_key "id:string" # required
  #   dsl.sort_key  "created_at:string" # optional
  #   dsl.provisioned_throughput(25)
  #   # dsl.execute # TODO: dsl.execute in here
  # end
end

