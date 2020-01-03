class Dynomite::Migration
  class Dsl
    extend Accessor
    include Dynomite::Client
    include ProvisionedThroughput
    include PrimaryKey
    include Index
    include Helpers

    attr_accessor :attribute_definitions,
                  :key_schema,
                  :table_name
    def initialize(method_name, table_name, &block)
      @method_name = method_name
      @table_name = table_name
      @block = block

      # Dsl fills in atttributes in as methods are called within the block
      # when parition_key and sort_key are called.
      # Attributes for both create_table and updated_table:
      @attribute_definitions = []
      # dont set billing_mode for update_table. otherwise creating an index can set billing_mode to PAY_PER_REQUEST without user knowing
      @billing_mode = "PAY_PER_REQUEST" if @method_name == :create_table
      @provisioned_throughput = nil

      # Attributes for create_table only:
      @key_schema = []

      # Attributes for update_table only:
      @gsi_indexes = []
      @lsi_indexes = []
    end

    def namespaced_table_name
      table_name_with_namespace(table_name)
    end

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
      send "params_#{@method_name}" # IE: params_create_table, params_update_table, params_delete_table
    end

    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#create_table-instance_method
    def params_create_table
      params = {
        billing_mode: @billing_mode.to_s.upcase,
        table_name: namespaced_table_name,
        key_schema: @key_schema,
        provisioned_throughput: @provisioned_throughput,
        tags: @tags, # only for create_table
      }
      params.reject! { |k,v| v.blank? }

      params[:local_secondary_indexes] = lsi_secondary_index_creates unless @lsi_indexes.empty?
      params[:global_secondary_indexes] = gsi_secondary_index_creates unless @gsi_indexes.empty?
      params[:attribute_definitions] = attribute_definitions
      params.merge!(common_params)
      params
    end

    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#update_table-instance_method
    dsl_accessor :replica_updates
    def params_update_table
      params = {
        billing_mode: @billing_mode.to_s.upcase,
        table_name: namespaced_table_name,
        # update table take values only some values for the "parent" table
        # no key_schema, update_table does not handle key_schema for the "parent" table
        replica_updates: @replica_updates, # only for update_table
      }
      params.reject! { |k,v| v.blank? }

      # only set "parent" table provisioned_throughput if user actually invoked it in the dsl
      params[:provisioned_throughput] = @provisioned_throughput if @provisioned_throughput_set_called
      params[:global_secondary_index_updates] = global_secondary_index_updates unless @gsi_indexes.empty?
      params[:attribute_definitions] = attribute_definitions
      params
    end

    def params_delete_table
      { table_name: namespaced_table_name }
    end

    def tags(values=nil)
      if values.nil?
        @tags
      else
        if values.is_a?(Hash)
          @tags = values.map do |key,value|
            {key: key.to_s, value: value.to_s}
          end
        else
          @tags = values
        end
      end
    end

    # @attribute_definitions only hold the partition_key and sort_key attributes
    # We'll also added the attributes from: 1. lsi index 2. gsi indexes 3. existing attributes for update table
    def attribute_definitions
      # Goes through all the lsi_indexes that have been built up in memory.
      # Find the lsi object that creates an index and then grab the attribute_definitions from it.
      # All lsi indexes are create. There is no update or delete for lsi indexes.
      @lsi_indexes.each do |lsi|
        lsi.attribute_definitions.each do |definition|
          @attribute_definitions << definition unless @attribute_definitions.include?(definition)
        end
      end

      # Goes through all the gsi_indexes that have been built up in memory.
      # Find the gsi object that creates an index and then grab the attribute_definitions from it.
      @gsi_indexes.select { |i| i.action == :create }.each do |gsi|
        gsi.attribute_definitions.each do |definition|
          @attribute_definitions << definition unless @attribute_definitions.include?(definition)
        end
      end

      # Merge existing attributes for update table
      if @method_name == :update_table
        existing_attributes = desc_table(namespaced_table_name).attribute_definitions
        existing_attributes.each do |attribute_definition|
          definition = attribute_definition.to_h
          @attribute_definitions << definition unless @attribute_definitions.include?(definition)
        end
      end

      @attribute_definitions
    end

    dsl_accessor :stream_specification, :sse_specification
    # common to create_table and update_table
    def common_params
      params = {
        stream_specification: @stream_specification,
        sse_specification: @sse_specification,
        deletion_protection_enabled: deletion_protection_enabled_value,
      }
      params.reject! { |k,v| v.blank? }
    end

    def deletion_protection_enabled(value=true)
      @deletion_protection_enabled = value
    end
    alias deletion_protection deletion_protection_enabled

    # To avoid name conflict with DSL t.deletion_protection_enabled
    def deletion_protection_enabled_value
      default = Dynomite.config.migration.deletion_protection_enabled
      @deletion_protection_enabled.nil? ? default : @deletion_protection_enabled
    end
  end
end
