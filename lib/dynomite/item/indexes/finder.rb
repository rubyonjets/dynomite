module Dynomite::Item::Indexes
  class Finder
    def initialize(source, query)
      @source, @query = source, query
    end

    # It's possible to have multiple indexes with the same partition and sort key.
    # Will use the first one we find.
    def find
      @source.indexes.find do |i|
        intersect = fields & i.fields
        intersect == i.fields
      end
    end

    def fields
      @query[:where].inject([]) do |result, hash|
        result += hash.keys
      end.uniq.sort.map(&:to_s)
    end
  end
end
