# Base class for LocalSecondaryIndex and GlobalSecondaryIndex
class Dynomite::Migration::Dsl
  class BaseSecondaryIndex
    include Common

    attr_accessor :action, :key_schema, :attribute_definitions
    attr_accessor :index_name
    def initialize(action, index_name=nil, &block)
      @action = action.to_sym
      # for gsi action can be: :create, :update, :delete
      # for lsi action is always: :create
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

    def evaluate
      return if @evaluated
      @block.call(self) if @block
      @evaluated = true
    end

    def params
      evaluate # lazy evaluation: wait until as long as possible before evaluating code block

      params = { index_name: index_name } # required for all actions

      if @action == :create
        params[:key_schema] = @key_schema # required for create action
        # hardcode to ALL for now
        params[:projection] = { # required
          projection_type: "ALL", # accepts ALL, KEYS_ONLY, INCLUDE
          # non_key_attributes: ["NonKeyAttributeName"],
        }
      end

      if [:create, :update].include?(@action)
        params[:provisioned_throughput] = @provisioned_throughput
      end

      params
    end
  end
end
