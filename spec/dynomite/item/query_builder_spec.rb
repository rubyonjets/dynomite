class QueryBuilderTester < Dynomite::Item
end

describe Dynomite::Item::QueryBuilder do
  let(:model) { QueryBuilderTester }

  it "to_params" do
    params = model.where(name: "Tung Nguyen", active: true).where(email: "tung@boltops.com").to_params
    expect(params).to eq(
      {:expression_attribute_names=>
        {"#name"=>"name", "#active"=>"active", "#email"=>"email"},
       :expression_attribute_values=>
        {":name"=>"Tung Nguyen", ":active"=>true, ":email"=>"tung@boltops.com"},
       :filter_expression=>"#name = :name AND #active = :active AND #email = :email"}
    )
  end

  it "execute" do
    builder = model.where(name: "Tung Nguyen", active: true).where(email: "tung@boltops.com")
    builder.execute
  end
end
