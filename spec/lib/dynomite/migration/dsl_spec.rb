require "spec_helper"

describe Dynomite::Migration::Dsl do
  # Supports this DSL, the `t` variable passed to the block is the Dsl instance
  #
  # class CreateCommentsMigration < Dynomite::Migration
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
      Dynomite::Migration::Dsl.db = double("db").as_null_object
      Dynomite::Migration::Dsl.new(:create_table, "posts")
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
      Dynomite::Migration::Dsl.db = double("db").as_null_object
      Dynomite::Migration::Dsl.new(:update_table, "comments")
    end

    it "builds up the gsi index params" do
      dsl.provisioned_throughput(18)

      dsl.gsi(:create) do |i|
        i.partition_key "post_id:string"
        i.sort_key "updated_at:string" # optional
      end
      dsl.gsi(:update, "another-index") do |i|
        i.provisioned_throughput(8)
      end
      dsl.gsi(:delete, "old-index")

      params = dsl.params
      # pp params # uncomment out to inspect params
      # attribute_definitions is a Double because we've mocked out:
      # Dynomite::Migration::Dsl.db = double("db").as_null_object
      expect(params.key?(:attribute_definitions)).to be true
      expect(params.key?(:global_secondary_index_updates)).to be true
      global_secondary_index_updates = params[:global_secondary_index_updates]
      index_actions = global_secondary_index_updates.map {|hash| hash.keys.first }
      expect(index_actions.sort).to eq([:create, :update, :delete].sort)
    end
  end

  # it "execute uses what the dsl methods built up in memory and translates it dynmaodb params that then get used to execute and run the command" do
  #   dsl.partition_key "id:string" # required
  #   dsl.sort_key  "created_at:string" # optional
  #   dsl.provisioned_throughput(25)
  #   # dsl.execute # TODO: dsl.execute in here
  # end
end

