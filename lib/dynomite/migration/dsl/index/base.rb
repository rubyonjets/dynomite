module Dynomite::Migration::Dsl::Index
  class Base
    include Dynomite::Types

    def partition_key_attribute_name
      get_attribute_name(:partition_key)
    end

    def sort_key_attribute_name
      get_attribute_name(:sort_key)
    end

    def get_attribute_name(field=:partition_key)
      value = instance_variable_get("@#{field}") # IE: @partition_key
      value.to_s.split(':').first if value
    end

    def partition_key_attribute_type
      get_attribute_type(:partition_key)
    end

    def sort_key_attribute_type
      get_attribute_type(:sort_key)
    end

    def get_attribute_type(field=:partition_key)
      value = instance_variable_get("@#{field}") # IE: @partition_key
      name, type = value.to_s.split(':')
      type ||= "string"
      type_map(type)
    end

    def conventional_index_name
      # DynamoDB requires index names to be at least 3 characters long, otherwise:
      #   Error: Unable to : 1 validation error detected: Value 'id' at 'globalSecondaryIndexes.1.member.indexName' failed to satisfy constraint: Member must have length greater than or equal to 3
      # The id valid is too short sadly.
      # Adding -index to the end of the index name is a safe way to ensure that.
      # Annoying that the index_name("id-index") is going to be a little longer.
      [partition_key_attribute_name, sort_key_attribute_name, 'index'].compact.join('-')
    end
  end
end
