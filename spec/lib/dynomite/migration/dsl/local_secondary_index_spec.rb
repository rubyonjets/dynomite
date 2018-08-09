require "spec_helper"

LSI = Dynomite::Migration::Dsl::LocalSecondaryIndex

describe LSI do
  context "create index" do
    let(:index) do
      Dynomite::Migration::Dsl.db = double("db").as_null_object
      LSI.new
    end

    # Supports this DSL, the `i` variable passed to the block is the
    # Dsl::GlobalSecondaryIndex instance
    #
    # class UpdateCommentsMigration < Dynomite::Migration
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

    context "parititon_key provided only" do
      it "index_name" do
        index.partition_key "post_id:string" # required
        expect(index.params[:index_name]).to eq("post_id-index")
      end
    end

    context "parititon_key and sort_key provided" do
      it "index_name" do
        index.partition_key "post_id:string" # required
        index.sort_key  "created_at:string" # optional
        expect(index.params[:index_name]).to eq("post_id-created_at-index")

        expect(index.params).to eq({
          :index_name=>"post_id-created_at-index",
          :key_schema=>[
            {:attribute_name=>"post_id", :key_type=>"HASH"},
            {:attribute_name=>"created_at", :key_type=>"RANGE"}],
          :projection=>{:projection_type=>"ALL"},
          :provisioned_throughput=> {:read_capacity_units=>5, :write_capacity_units=>5}
        })
      end
    end

    it "execute uses what the dsl methods built up in memory and translates it dynmaodb params that then get used to execute and run the command" do
      index.partition_key "id:string" # required
      index.sort_key  "created_at:string" # optional
      index.provisioned_throughput(30)
      # index.execute # TODO: index.execute in here
    end
  end
end
