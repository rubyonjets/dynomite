class Dynomite::Migration
  class Dsl
    ATTRIBUTES = %i[
      key_schema
      attribute_definitions
      table_name
      billing_mode
    ].freeze

    autoload :Common, "dynomite/migration/common"
    autoload :BaseSecondaryIndex, "dynomite/migration/dsl/base_secondary_index"
    autoload :LocalSecondaryIndex, "dynomite/migration/dsl/local_secondary_index"
    autoload :GlobalSecondaryIndex, "dynomite/migration/dsl/global_secondary_index"

    include Dynomite::DbConfig
    include Common

    attr_accessor(*ATTRIBUTES)

    def initialize(method_name, table_name, &block)
      @method_name = method_name
      @table_name = table_name
      @block = block

      # Dsl fills in attributes in as methods are called within the block.
      # Attributes for both create_table and updated_table:
      @billing_mode = 'PROVISIONED'
      @attribute_definitions = []
      @provisioned_throughput = {
        read_capacity_units: 5,
        write_capacity_units: 5
      }

      # Attributes for create_table only:
      @key_schema = []

      # Attributes for update_table only:
      @gsi_indexes = []
      @lsi_indexes = []
    end

    # t.billing_mode(:pay_per_request)
    # t.billing_mode(:provisioned) # default value
    def billing_mode(mode = nil)
      return @billing_mode if mode.nil?

      @billing_mode = mode.to_s.upcase
    end

    # t.gsi(:create) do |i|
    #   i.partition_key "category:string"
    #   i.sort_key "created_at:string" # optional
    # end
    def gsi(action=:create, index_name=nil, &block)
      gsi_index = GlobalSecondaryIndex.new(action, index_name, &block)
      @gsi_indexes << gsi_index # store @gsi_index for the parent Dsl to use
    end
    alias_method :global_secondary_index, :gsi

    # t.lsi(:create) do |i|
    #   i.partition_key "category:string"
    #   i.sort_key "created_at:string" # optional
    # end
    def lsi(action=:create, index_name=nil, &block)
      # dont need action create but have it to keep the lsi and gsi method consistent
      lsi_index = LocalSecondaryIndex.new(index_name, &block)
      @lsi_indexes << lsi_index # store @lsi_index for the parent Dsl to use
    end
    alias_method :local_secondary_index, :lsi

    def evaluate
      return if @evaluated
      @block.call(self) if @block
      @evaluated = true
    end

    # http://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/dynamo-example-create-table.html
    # build the params up from dsl in memory and provides params to the
      # executor
    def params
      evaluate # lazy evaluation: wait until as long as possible before evaluating code block

      # Not using send because think its clearer in this case
      case @method_name
      when :create_table
        params_create_table
      when :update_table
        params_update_table
      end
    end

    def params_create_table
      merge_lsi_attribute_definitions!
      merge_gsi_attribute_definitions!

      params = {
        table_name: namespaced_table_name,
        key_schema: @key_schema,
        attribute_definitions: @attribute_definitions,
        billing_mode: @billing_mode
      }

      params[:provisioned_throughput] = @provisioned_throughput if @billing_mode == 'PROVISIONED'
      params[:local_secondary_indexes] = lsi_secondary_index_creates unless @lsi_indexes.empty?
      params[:global_secondary_indexes] = gsi_secondary_index_creates unless @gsi_indexes.empty?
      params
    end

    def params_update_table
      merge_gsi_attribute_definitions!

      params = {
        table_name: namespaced_table_name,
        attribute_definitions: @attribute_definitions,
        billing_mode: @billing_mode
        # update table take values only some values for the "parent" table
        # no key_schema, update_table does not handle key_schema for the "parent" table
      }
      # only set "parent" table provisioned_throughput if user actually invoked
      # it in the dsl
      if @provisioned_throughput_set_called && @billing_mode == 'PROVISIONED'
        params[:provisioned_throughput] = @provisioned_throughput
      end
      params[:global_secondary_index_updates] = global_secondary_index_updates
      params
    end

    # Goes thorugh all the lsi_indexes that have been built up in memory.
    # Find the lsi object that creates an index and then grab the
    # attribute_definitions from it.
    def merge_lsi_attribute_definitions!
      lsi = @lsi_indexes.first # DynamoDB only supports adding one index at a time anyway. The reason @lsi_indexes is an Array is because we're sharing the same class code for LSI and GSI
      if lsi
        lsi.evaluate # force early evaluate since we need the params to
          # add: gsi_attribute_definitions + lsi_attrs
        lsi_attrs = lsi.attribute_definitions
      end
      all_attrs = if lsi_attrs
                    @attribute_definitions + lsi_attrs
                  else
                    @attribute_definitions
                  end
      @attribute_definitions = all_attrs.uniq
    end

    # maps each lsi to the hash structure expected by dynamodb update_table
    # under the global_secondary_index_updates key:
    #
    #   { create: {...} }
    #   { update: {...} }
    #   { delete: {...} }
    def lsi_secondary_index_creates
      @lsi_indexes.map do |lsi|
        lsi.params
      end
    end

    # maps each lsi to the hash structure expected by dynamodb update_table
    # under the global_secondary_index_updates key:
    #
    #   { create: {...} }
    #   { update: {...} }
    #   { delete: {...} }
    def gsi_secondary_index_creates
      @gsi_indexes.map do |gsi|
        gsi.params
      end
    end

    # Goes thorugh all the gsi_indexes that have been built up in memory.
    # Find the gsi object that creates an index and then grab the
    # attribute_definitions from it.
    def merge_gsi_attribute_definitions!
      gsi_attrs = []

      gsi = @gsi_indexes.find { |i| i.action == :create }
      if gsi
        gsi.evaluate # force early evaluate since we need the params to
          # add: gsi_attribute_definitions + gsi_attrs
        gsi_attrs = gsi.attribute_definitions
      end

      # Merge existing attributes for update table
      all_gsi_attrs = @method_name == :update_table ?
        gsi_attribute_definitions + gsi_attrs :
        gsi_attrs

      all_attrs = (@attribute_definitions + all_gsi_attrs).uniq
      @attribute_definitions = all_attrs
    end

    # maps each gsi to the hash structure expected by dynamodb update_table
    # under the global_secondary_index_updates key:
    #
    #   { create: {...} }
    #   { update: {...} }
    #   { delete: {...} }
    def global_secondary_index_updates
      @gsi_indexes.map do |gsi|
        { gsi.action => gsi.params }
      end
    end

    # >> resp = Post.db.describe_table(table_name: "demo-dev-posts")
    # >> resp.table.attribute_definitions.map(&:to_h)
    # => [{:attribute_name=>"id", :attribute_type=>"S"}]
    def gsi_attribute_definitions
      return @gsi_attribute_definitions if @gsi_attribute_definitions

      resp = db.describe_table(table_name: namespaced_table_name)
      @gsi_attribute_definitions = resp.table.attribute_definitions.map(&:to_h)
    end
  end
end
