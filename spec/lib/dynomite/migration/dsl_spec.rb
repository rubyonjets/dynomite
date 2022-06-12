require "spec_helper"

describe Dynomite::Migration::Dsl do
  around(:each) do |example|
    Dynomite::Migration::Dsl.db = Aws::DynamoDB::Client.new(stub_responses: true)
    example.run
    Dynomite::Migration::Dsl.db = nil
  end

  # Supports this DSL, the `t` variable passed to the block is the Dsl instance
  #
  # class CreateCommentsMigration < Dynomite::Migration
  #   def up
  #     create_table :comments do |t|
  #       t.partition_key "post_id:string" # required
  #       t.sort_key  "created_at:string" # optional
  #       t.billing_mode(:provisioned) # optional
  #       t.provisioned_throughput(5) # sets both read and write, defaults to 5 when not set
  #     end
  #   end
  # end
  context "create_table" do
    let(:dsl) { Dynomite::Migration::Dsl.new(:create_table, "posts") }
    subject { dsl.params }

    context "with billing_mode == :provisioned" do
      before(:each) do
        dsl.partition_key "id:string"
        dsl.sort_key "created_at:string"
        dsl.provisioned_throughput(25)
      end

      it "builds the DSL parameters in memory" do
        expect(subject[:key_schema]).to eq([
          {:attribute_name=>"id", :key_type=>"HASH"},
          {:attribute_name=>"created_at", :key_type=>"RANGE"}])
        expect(subject[:attribute_definitions]).to eq([
          {:attribute_name=>"id", :attribute_type=>"S"},
          {:attribute_name=>"created_at", :attribute_type=>"S"}])
        expect(subject[:provisioned_throughput]).to eq(
          :read_capacity_units=>25,
          :write_capacity_units=>25
        )
        expect(subject[:billing_mode]).to eq("PROVISIONED")
      end
    end

    context "with billing_mode == :pay_per_request" do
      before(:each) do
        dsl.partition_key "PK:string"
        dsl.sort_key "SK:string"
        dsl.billing_mode(:pay_per_request)
        # NOTE: billing_mode :pay_per_request will override provisioned_throughput
        dsl.provisioned_throughput(25)
      end

      it "builds the DSL parameters in memory" do
        expect(subject[:key_schema]).to eq([
          { attribute_name: "PK", key_type: "HASH" },
          { attribute_name: "SK", key_type: "RANGE" }
        ])
        expect(subject[:attribute_definitions]).to eq([
          { attribute_name: "PK", attribute_type: "S"},
          { attribute_name: "SK", attribute_type: "S"}
        ])
        expect(subject[:billing_mode]).to eq("PAY_PER_REQUEST")
        expect(subject[:provisioned_throughput]).to be_nil
      end
    end
  end

  context "update_table" do
    let(:dsl) { Dynomite::Migration::Dsl.new(:update_table, "comments") }

    context "with billing_mode == :provisioned" do
      it "builds up the gsi index params" do
        dsl.provisioned_throughput(18)
        allow(dsl).to receive(:gsi_attribute_definitions).and_return([])

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
        expect(params[:provisioned_throughput]).to eq(
          read_capacity_units: 18,
          write_capacity_units: 18
        )
      end
    end

    context "with billing_mode == :pay_per_request" do
      subject { dsl.params }

      before(:each) do
        dsl.billing_mode(:pay_per_request)
      end

      it "sets the billing mode" do
        expect(subject[:billing_mode]).to eq('PAY_PER_REQUEST')
        expect(subject[:provisioned_throughput]).to be_nil
      end
    end
  end

  # it "execute uses what the dsl methods built up in memory and translates it dynmaodb params that then get used to execute and run the command" do
  #   dsl.partition_key "id:string" # required
  #   dsl.sort_key  "created_at:string" # optional
  #   dsl.provisioned_throughput(25)
  #   # dsl.execute # TODO: dsl.execute in here
  # end
end
