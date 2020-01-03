class QueryParamsTester < Dynomite::Item
end

class QueryParamsWithSortKeyTester < Dynomite::Item
  # def partition_key; :foo; end
  # def sort_key; :bar; end
end

describe Dynomite::Item::Query::Params do
  before(:each) do
    allow(QueryParamsTester).to receive(:partition_key).and_return(:id)
    allow(QueryParamsTester).to receive(:sort_key).and_return(nil)
    allow(QueryParamsWithSortKeyTester).to receive(:partition_key).and_return(:foo)
    allow(QueryParamsWithSortKeyTester).to receive(:partition_key).and_return(:bar)
  end

  let(:tester) { QueryParamsTester }
  let(:params) do
    params = Dynomite::Item::Query::Params.new(source, query)
    allow(params).to receive(:index_finder).and_return(index_finder)
    params
  end
  let(:index_finder) do
    finder = double(:null).as_null_object
    allow(finder).to receive(:find).and_return index
    finder
  end
  let(:source) { tester }

  context "no indexes" do
    let(:index) { nil }
    context "hash with multiple keys chained" do
      let(:query) { {where: [{name: "Tung", active: true},{email: "tung@boltops.com"}]} }
      it "builds params" do
        expect(params.to_h).to eq(
          {:expression_attribute_names=>
            {"#name"=>"name", "#active"=>"active", "#email"=>"email"},
          :expression_attribute_values=>
            {":name"=>"Tung", ":active"=>true, ":email"=>"tung@boltops.com"},
          :filter_expression=>"#name = :name AND #active = :active AND #email = :email",
          :table_name => "dynomite_query_params_testers"}
        )
      end
    end

    context "hash with single key chained" do
      let(:query) { {where: [{name: "Tung", active: true},{email: "tung@boltops.com"}]} }
      it "builds params" do
        expect(params.to_h).to eq(
          {:expression_attribute_names=>
            {"#name"=>"name", "#active"=>"active", "#email"=>"email"},
          :expression_attribute_values=>
            {":name"=>"Tung", ":active"=>true, ":email"=>"tung@boltops.com"},
          :filter_expression=>"#name = :name AND #active = :active AND #email = :email",
          :table_name=>"dynomite_query_params_testers"}
        )
      end
    end

    context "indexes" do
      let(:index) do
        index = Dynomite::Item::Indexes::Index.new({})
        allow(index).to receive(:index_name).and_return("email-index")
        allow(index).to receive(:fields).and_return(["email"])
        index
      end

      context "hash with single key chained" do
        let(:query) { {where: [{name: "Tung", active: true},{email: "tung@boltops.com"}]} }
        it "builds params" do
          expect(params.to_h).to eq(
            {:expression_attribute_names=>
              {"#name"=>"name", "#active"=>"active", "#email"=>"email"},
            :expression_attribute_values=>
              {":name"=>"Tung", ":active"=>true, ":email"=>"tung@boltops.com"},
            :filter_expression=>"#name = :name AND #active = :active",
            :key_condition_expression=>"#email = :email",
            :table_name=>"dynomite_query_params_testers",
            :index_name=>"email-index"}
          )
        end
      end

      context "query by partition key" do
        let(:tester) { QueryParamsWithSortKeyTester }
        let(:index) do
          Dynomite::Item::Indexes::PrimaryIndex.new(['foo'])
        end

        context "uses key_condition_expression for the partition key field" do
          let(:query) { {where: [{foo: 'abcdef'}]} }
          it "builds params" do
            allow(params).to receive(:sort_key).and_return(:bar)
            expect(params.to_h).to eq(
              expression_attribute_names: { '#foo' => 'foo' },
              expression_attribute_values: { ':foo' => 'abcdef' },
              key_condition_expression: "#foo = :foo",
              table_name: 'dynomite_query_params_with_sort_key_testers'
            )
          end
        end
      end

      context "scan_index_forward" do
        let(:index) do
          index = Dynomite::Item::Indexes::Index.new({})
          allow(index).to receive(:index_name).and_return("name-index")
          allow(index).to receive(:fields).and_return(["name"])
          index
        end

        context "true" do
          let(:query) { {where: [{name: "Tung"}], scan_index_forward: true} }
          it "builds params" do
            expect(params.to_h).to eq({
              :expression_attribute_names=>{"#name"=>"name"},
              :expression_attribute_values=>{":name"=>"Tung"},
              :key_condition_expression=>"#name = :name",
              :index_name => "name-index",
              :table_name=>"dynomite_query_params_testers",
              :scan_index_forward => true,
            })
          end
        end

        context "false" do
          let(:query) { {where: [{name: "Tung"}], scan_index_forward: false} }
          it "builds params" do
            expect(params.to_h).to eq({
              :expression_attribute_names=>{"#name"=>"name"},
              :expression_attribute_values=>{":name"=>"Tung"},
              :key_condition_expression=>"#name = :name",
              :index_name => "name-index",
              :table_name=>"dynomite_query_params_testers",
              :scan_index_forward => false,
            })
          end
        end
      end
    end

    context "comparision in" do
      context "gt" do
        let(:query) { {where: [{name: "Tung", "age.gt": 30}]} }
        it "single value" do
          expect(params.to_h).to eq(
            {:expression_attribute_names=>{"#name"=>"name", "#age"=>"age"},
            :expression_attribute_values=>{":name"=>"Tung", ":age"=>30},
            :filter_expression=>"#name = :name AND #age > :age",
            :table_name=>"dynomite_query_params_testers"}
          )
        end
      end

      context "in" do
        let(:query) { {where: [{name: "Tung", "age.in": [30,35]}]} }
        it "single value" do
          expect(params.to_h).to eq(
            {:expression_attribute_names=>{"#name"=>"name", "#age"=>"age"},
            :expression_attribute_values=>{":name"=>"Tung", ":age0"=>30, ":age1"=>35},
            :filter_expression=>"#name = :name AND #age IN (:age0, :age1)",
            :table_name=>"dynomite_query_params_testers"}
          )
        end
      end

      context "between" do
        let(:query) { {where: [{name: "Tung", "age.between": [30,35]}]} }
        it "single value" do
          expect(params.to_h).to eq(
            {:expression_attribute_names=>{"#name"=>"name", "#age"=>"age"},
            :expression_attribute_values=>{":name"=>"Tung", ":age0"=>30, ":age1"=>35},
            :filter_expression=>"#name = :name AND #age BETWEEN :age0 AND :age1",
            :table_name=>"dynomite_query_params_testers"}
          )
        end
      end

      context "begins_with" do
        let(:query) { {where: [{name: "Tung", "age.begins_with": 30}]} }
        it "single value" do
          expect(params.to_h).to eq(
            {:expression_attribute_names=>{"#name"=>"name", "#age"=>"age"},
            :expression_attribute_values=>{":name"=>"Tung", ":age"=>30},
            :filter_expression=>"#name = :name AND BEGINS_WITH(#age, :age)",
            :table_name=>"dynomite_query_params_testers"}
          )
        end
      end
    end
  end
end
