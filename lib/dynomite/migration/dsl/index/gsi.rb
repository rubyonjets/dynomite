module Dynomite::Migration::Dsl::Index
  class Gsi < Base
    attr_reader :action, :attrs
    def initialize(action, attrs)
      @action = action
      @params = attrs.dup
      # Delete the special DSL keys. Keep the rest and pass through to AWS create_table or update_table
      @partition_key = @params.delete(:partition_key) || @params.delete(:hash_key) # required for create, optional for update (only index needed)
      @sort_key = @params.delete(:sort_key) || @params.delete(:range_key)          # optional for create
    end

    def params
      send("params_#{@action}")
    end

    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#create_table-instance_method
    def params_create
      @params[:key_schema] ||= []
      # HASH - add to beginning of array
      @params[:key_schema].unshift(attribute_name: partition_key_attribute_name, key_type: "HASH") unless @partition_key.blank?
      # RANGE - add to end of array
      @params[:key_schema] << {attribute_name: sort_key_attribute_name, key_type: "RANGE"} unless @sort_key.blank?
      @params[:index_name] ||= conventional_index_name
      @params[:projection] ||= {projection_type: "ALL"}
      @params[:provisioned_throughput] = normalize_provisioned_throughput(@params[:provisioned_throughput]) if @params[:provisioned_throughput]
      @params
    end

    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#update_table-instance_method
    def params_update
      @params[:index_name] ||= conventional_index_name
      @params[:provisioned_throughput] = normalize_provisioned_throughput(@params[:provisioned_throughput]) if @params[:provisioned_throughput]
      @params
    end

    def params_delete
      @params[:index_name] ||= conventional_index_name
      @params
    end

    def attribute_definitions
      definitions = []
      definitions << {attribute_name: partition_key_attribute_name, attribute_type: partition_key_attribute_type} unless @partition_key.blank?
      definitions << {attribute_name: sort_key_attribute_name, attribute_type: sort_key_attribute_type} unless @sort_key.blank?
      definitions
    end

    def normalize_provisioned_throughput(value)
      if value.is_a?(Hash)
        value
      else
        {
          read_capacity_units: value,
          write_capacity_units: value,
        }
      end
    end
  end
end
