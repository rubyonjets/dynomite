class DynamodbModel::Migration::Dsl
  class GlobalSecondaryIndex
    include Common

    ATTRIBUTE_TYPE_MAP = DynamodbModel::Migration::Dsl::ATTRIBUTE_TYPE_MAP

    attr_accessor :action, :key_schema, :attribute_definitions
    def initialize(action, index_name=nil, &block)
      @action = action.to_sym # :create, :update, :index
      @index_name = index_name
      @block = block

      # Dsl fills these atttributes in as methods are called within
      # the block
      @key_schema = []
      @attribute_definitions = []
      # default provisioned_throughput
      @provisioned_throughput = {
        read_capacity_units: 5,
        write_capacity_units: 5
      }
    end

    def index_name
      @index_name || conventional_index_name
    end

    def conventional_index_name
      # @partition_key_identifier and @sort_key_identifier are set as immediately
      # when the partition_key and sort_key methods are called in the dsl block.
      # Usually look like this:
      #
      #   @partition_key_identifier: post_id:string
      #   @sort_key_identifier: updated_at:string
      #
      # We strip the :string portion in case it is provided
      #
      partition_key = @partition_key_identifier.split(':').first
      sort_key = @sort_key_identifier.split(':').first if @sort_key_identifier
      [partition_key, sort_key, "index"].compact.join('-')
    end

    def params
      {
        index_name: index_name, # required
        key_schema: @key_schema, # # required
        # hardcode to ALL for now
        projection: { # required
          projection_type: "ALL", # accepts ALL, KEYS_ONLY, INCLUDE
          # non_key_attributes: ["NonKeyAttributeName"],
        },
        provisioned_throughput: @provisioned_throughput,
      }
    end
  end
end
