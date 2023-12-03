class QueryRelationTester < Dynomite::Item
end

class QueryRelationWithSortKeyTester < Dynomite::Item
  # partition_key :foo
  # sort_key :bar
end

describe Dynomite::Item::Query::Relation do
  before(:each) do
    allow(QueryRelationTester).to receive(:partition_key).and_return(:id)
    allow(QueryRelationTester).to receive(:sort_key).and_return(nil)
    allow(QueryRelationWithSortKeyTester).to receive(:partition_key).and_return(:foo)
    allow(QueryRelationWithSortKeyTester).to receive(:partition_key).and_return(:bar)
  end

  let(:tester) { QueryRelationTester }
  let(:relation) do
    relation = Dynomite::Item::Query::Relation.new(tester)
    allow(relation).to receive(:index_finder).and_return(index_finder)
    relation
  end
  let(:index_finder) do
    finder = double(:null).as_null_object
    allow(finder).to receive(:find).and_return index
    finder
  end
end
