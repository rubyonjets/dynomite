class DynamodbModel::Migration::Dsl
  class GlobalSecondaryIndex
    include Common

    ATTRIBUTE_TYPE_MAP = DynamodbModel::Migration::Dsl::ATTRIBUTE_TYPE_MAP

    attr_accessor :key_schema, :attribute_definitions
    def initialize(action, index_name=nil, &block)
      @action = action # :create, :update, :index
      @index_name = index_name
      @block = block

      # Dsl fills these atttributes in as methods are called within
      # the block
      @key_schema = []
      @attribute_definitions = []
      @provisioned_throughput = {
        read_capacity_units: 10,
        write_capacity_units: 10
      }
    end

    def data
      "some data"
      # {
      #   key_schema:
      # }
    end
  end
end
