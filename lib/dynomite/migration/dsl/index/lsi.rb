module Dynomite::Migration::Dsl::Index
  class Lsi < Base
    attr_reader :attrs
    def initialize(partition_key_name, attrs)
      @partition_key_name = partition_key_name
      @params = attrs.dup
      # Delete the special DSL keys. Keep the rest and pass through to AWS create_table or update_table
      @sort_key = @params.delete(:sort_key) || @params.delete(:range_key) # require for LSI index since it must be a composite key
    end

    def params
      @params[:key_schema] ||= []
      @params[:key_schema] << {attribute_name: @partition_key_name, key_type: "HASH"}
      @params[:key_schema] << {attribute_name: sort_key_attribute_name, key_type: "RANGE"}
      @params[:index_name] ||= conventional_index_name
      @params[:projection] ||= {projection_type: "ALL"}
      @params
    end

    def attribute_definitions
      definitions = []
      definitions << {attribute_name: partition_key_attribute_name, attribute_type: partition_key_attribute_type} unless @partition_key.blank?
      definitions << {attribute_name: sort_key_attribute_name, attribute_type: sort_key_attribute_type} unless @sort_key.blank?
      definitions
    end
  end
end
