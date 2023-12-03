module Dynomite::Item::Indexes
  class Finder
    extend Memoist
    include Dynomite::Client

    def initialize(source, query)
      @source, @query = source, query
    end

    def find(index_name=nil)
      if index_name # explicit index name
        index = @source.indexes.find { |i| i.index_name == index_name }
        if index
          return index
        else
          logger.info <<~EOL
            WARN: Index #{index_name} specified but not found for table #{@source.table_name}
            Falling back to auto-discovery of indexes
          EOL
        end
      end

      # auto-discover
      find_primary_key_index || find_secondary_index
    end

    def find_primary_key_index
      PrimaryIndex.new(@source.primary_key_fields) if primary_key_found?
    end

    def primary_key_found?
      if @source.composite_key?
        query_fields.include?(@source.partition_key_field) && query_fields.include?(@source.sort_key_field)
      else
        query_fields.include?(@source.partition_key_field)
      end
    end

    # It's possible to have multiple indexes with the same partition and sort key.
    # Will use the first one we find.
    def find_secondary_index
      @source.indexes.find do |i|
        # If query field has comparision expression like
        #   Product.where("category.in": ["Electronics"]).count
        # then it wont match, which is correct.
        intersect = query_fields & i.fields
        intersect == i.fields
      end
    end

    def query_fields
      @query[:where].inject([]) do |result, where_group|
        result += where_group.fields
      end.uniq.sort.map(&:to_s)
    end
    memoize :query_fields
  end
end
