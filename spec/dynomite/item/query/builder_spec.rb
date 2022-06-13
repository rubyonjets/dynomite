class QueryBuilderTester < Dynomite::Item
end

class QueryBuilderWithSortKeyTester < Dynomite::Item
  partition_key :foo
  sort_key :bar
end

describe Dynomite::Item::Query::Builder do
  let(:tester) { QueryBuilderTester }
  let(:builder) do
    builder = Dynomite::Item::Query::Builder.new(tester)
    builder.instance_variable_set(:@index_finder, index_finder)
    builder
  end
  let(:index_finder) do
    finder = double(:null).as_null_object
    allow(finder).to receive(:find).and_return index
    finder
  end

  context "no indexes" do
    let(:index) { nil }

    it "hash with multiple keys chained" do
      b = builder.where(name: "Tung Nguyen", active: true).where(email: "tung@boltops.com")
      expect(b.to_params).to eq(
        {:expression_attribute_names=>
          {"#name"=>"name", "#active"=>"active", "#email"=>"email"},
         :expression_attribute_values=>
          {":name"=>"Tung Nguyen", ":active"=>true, ":email"=>"tung@boltops.com"},
         :filter_expression=>"#name = :name AND #active = :active AND #email = :email",
         :table_name => "dynomite_query_builder_testers"}
      )
    end

    it "hash with single key chained" do
      b = builder.where(name: "Tung Nguyen", active: true).where(email: "tung@boltops.com")
      expect(b.to_params).to eq(
        {:expression_attribute_names=>
          {"#name"=>"name", "#active"=>"active", "#email"=>"email"},
         :expression_attribute_values=>
          {":name"=>"Tung Nguyen", ":active"=>true, ":email"=>"tung@boltops.com"},
         :filter_expression=>"#name = :name AND #active = :active AND #email = :email",
         :table_name=>"dynomite_query_builder_testers"}
      )
    end
  end

  context "indexes" do
    let(:index) do
      index = Dynomite::Item::Indexes::Index.new({})
      allow(index).to receive(:index_name).and_return("fake-email-index")
      allow(index).to receive(:fields).and_return(["email"])
      index
    end

    it "hash with single key chained" do
      b = builder.where(name: "Tung Nguyen", active: true).where(email: "tung@boltops.com")
      expect(b.to_params).to eq(
        {:expression_attribute_names=>
          {"#name"=>"name", "#active"=>"active", "#email"=>"email"},
         :expression_attribute_values=>
          {":name"=>"Tung Nguyen", ":active"=>true, ":email"=>"tung@boltops.com"},
         :filter_expression=>"#name = :name AND #active = :active",
         :key_condition_expression=>"#email = :email",
         :table_name=>"dynomite_query_builder_testers",
         :index_name=>"fake-email-index"}
      )
    end
  end

  context "query by partition key" do
    let(:tester) { QueryBuilderWithSortKeyTester }

    let(:index) do
      Dynomite::Item::Indexes::PrimaryIndex.new('foo')
    end

    it "uses key_condition_expression for the partition key field" do
      b = builder.where(foo: 'abcdef')
      expect(b.to_params).to eq(
         expression_attribute_names: { '#foo' => 'foo' },
         expression_attribute_values: { ':foo' => 'abcdef' },
         key_condition_expression: "#foo = :foo",
         table_name: 'dynomite_query_builder_with_sort_key_testers'
       )
    end
  end
end
