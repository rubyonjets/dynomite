module Dynomite::Item::Indexes
  class Index
    delegate :index_name, :key_schema, :projection, :index_status, :index_size_bytes, :item_count, :index_arn,
      to: :data

    attr_reader :data
    def initialize(data)
      @data = data # from describe_table.table.global_secondary_indexes items
    end

    def fields
      key_schema.map do |hash|
        hash.attribute_name
      end.sort
    end
  end
end
