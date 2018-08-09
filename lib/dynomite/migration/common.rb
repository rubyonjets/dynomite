# Common methods to the *SecondaryIndex classes that handle gsi and lsi methods
# as well a the Dsl class that handles create_table and update_table methods.
class Dynomite::Migration::Dsl
  module Common
    # http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Types/KeySchemaElement.html
    # partition_key is required
    def partition_key(identifier)
      @partition_key_identifier = identifier # for later use. useful for conventional_index_name
      adjust_schema_and_attributes(identifier, "hash")
    end

    # sort_key is optional
    def sort_key(identifier)
      @sort_key_identifier = identifier # for later use. useful for conventional_index_name
      adjust_schema_and_attributes(identifier, "range")
    end

    # Parameters:
    #   identifier: "id:string" or "id"
    #   key_type: "hash" or "range"
    #
    # Adjusts the parameters for create_table to add the
    # partition_key and sort_key
    def adjust_schema_and_attributes(identifier, key_type)
      name, attribute_type = identifier.split(':')
      attribute_type = "string" if attribute_type.nil?

      partition_key = {
        attribute_name: name,
        key_type: key_type.upcase
      }
      @key_schema << partition_key

      attribute_definition = {
        attribute_name: name,
        attribute_type: Dynomite::ATTRIBUTE_TYPES[attribute_type]
      }
      @attribute_definitions << attribute_definition
    end

    # t.provisioned_throughput(5) # both
    # t.provisioned_throughput(:read, 5)
    # t.provisioned_throughput(:write, 5)
    # t.provisioned_throughput(:both, 5)
    def provisioned_throughput(*params)
      case params.size
      when 0 # reader method
        return @provisioned_throughput # early return
      when 1
        # @provisioned_throughput_set_called useful for update_table
        # only provide a provisioned_throughput settings if explicitly called for update_table
        @provisioned_throughput_set_called = true
        arg = params[0]
        if arg.is_a?(Hash)
          # Case:
          # provisioned_throughput(
          #   read_capacity_units: 10,
          #   write_capacity_units: 10
          # )
          @provisioned_throughput = arg # set directly
          return # early return
        else # assume parameter is an Integer
          # Case: provisioned_throughput(10)
          capacity_type = :both
          capacity_units = arg
        end
      when 2
        @provisioned_throughput_set_called = true
        # Case: provisioned_throughput(:read, 5)
        capacity_type, capacity_units = params
      end

      map = {
        read: :read_capacity_units,
        write: :write_capacity_units,
      }

      if capacity_type == :both
        @provisioned_throughput[map[:read]] = capacity_units
        @provisioned_throughput[map[:write]] = capacity_units
      else
        @provisioned_throughput[capacity_type] = capacity_units
      end
    end
  end
end
