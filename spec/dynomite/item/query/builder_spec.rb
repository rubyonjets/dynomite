class QueryBuilderTester < Dynomite::Item
end

describe Dynomite::Item::Query::Builder do
  let(:builder) do
    builder = Dynomite::Item::Query::Builder.new(QueryBuilderTester)
    builder.instance_variable_set(:@index_finder, index_finder)
    builder
  end

  context "to_params with no indexes" do
    let(:index_finder) do
      finder = double(:null).as_null_object
      allow(finder).to receive(:find).and_return nil
      finder
    end

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
end
