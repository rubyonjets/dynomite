# Common methods to the *SecondaryIndex classes that handle gsi and lsi methods
# as well a the Dsl class that handles create_table and update_table methods.
class Dynomite::Migration::Dsl
  module PrimaryKey
    include Dynomite::Types

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Types/KeySchemaElement.html
    # partition_key is required
    attr_reader :partition_key_identifier
    def partition_key(identifier)
      identifier = identifier.to_s
      @partition_key_identifier = identifier # for later use. useful for conventional_index_name
      adjust_schema_and_attributes(identifier, "HASH")
    end

    # sort_key is optional
    attr_reader :sort_key_identifier
    def sort_key(identifier)
      identifier = identifier.to_s
      @sort_key_identifier = identifier # for later use. useful for conventional_index_name
      adjust_schema_and_attributes(identifier, "RANGE")
    end

    # Use class variable to share across all instances of GlobalSecondaryIndex
    # Note: Even though dynomite merges attribute defintions correctly for
    # multiple indexes, DynamoDB does not allow creating multiple indexes
    # at the same time. Example error:
    #   Unable to update table: Subscriber limit exceeded: Only 1 online index can be created or deleted simultaneously per table
    # Leaving the logic in place in case AWS changes this in the future.

    # Parameters:
    #   identifier: "id:string" or "id"
    #   key_type: "HASH" OR "RANGE"
    #
    # Adjusts the parameters for create_table to add the
    # partition_key and sort_key
    def adjust_schema_and_attributes(identifier, key_type)
      name, attribute_type = identifier.split(':')
      attribute_type ||= "string" # default to string

      partition_key = {
        attribute_name: name,
        key_type: key_type.upcase
      }

      if partition_key[:key_type] == "RANGE"
        @key_schema << partition_key unless @key_schema.include?(partition_key)
      else # HASH - add to beginning
        @key_schema.unshift(partition_key) unless @key_schema.include?(partition_key)
      end

      attribute_definition = {
        attribute_name: name,
        attribute_type: type_map(attribute_type)
      }
      unless @attribute_definitions.include?(attribute_definition)
        @attribute_definitions << attribute_definition
      end
      @attribute_definitions
    end
  end
end
