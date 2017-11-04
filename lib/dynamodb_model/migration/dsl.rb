class DynamodbModel::Migration
  class Dsl
    include DynamodbModel::DbConfig

    ATTRIBUTE_TYPE_MAP = {
      'string' => 'S',
      'number' => 'N',
      'binary' => 'B',
      's' => 'S',
      'n' => 'N',
      'b' => 'B',
    }

    attr_accessor :key_schema, :attribute_definitions
    # db is the dynamodb client
    def initialize(table_name)
      @table_name = table_name
      @key_schema = []
      @attribute_definitions = []
      @provisioned_throughput = {
        read_capacity_units: 10,
        write_capacity_units: 10
      }
    end

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Types/KeySchemaElement.html
    # partition_key is required
    def partition_key(identifier)
      adjust_schema_and_attributes(identifier, "hash")
    end

    # sort_key is optional
    def sort_key(identifier)
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
        attribute_type: ATTRIBUTE_TYPE_MAP[attribute_type]
      }
      @attribute_definitions << attribute_definition
    end

    # t.provisioned_throughput(5) # both
    # t.provisioned_throughput(:read, 5)
    # t.provisioned_throughput(:write, 5)
    # t.provisioned_throughput(:both, 5)
    def provisioned_throughput(*params)
      case params.size
      when 2
        capacity_type, capacity_units = params
      when 1
        arg = params[0]
        if arg.is_a?(Hash)
          @provisioned_throughput = arg # set directly
          return
        else # assume parameter is an Integer
          capacity_type = :both
          capacity_units = arg
        end
      when 0 # reader method
        return @provisioned_throughput
      end

      map = {
        read: :read_capacity_units,
        write: :write_capacity_units,
      }

      if capacity_type = :both
        @provisioned_throughput[map[:read]] = capacity_units
        @provisioned_throughput[map[:write]] = capacity_units
      else
        @provisioned_throughput[capacity_type] = capacity_units
      end
    end

    # http://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/dynamo-example-create-table.html
    def execute
      params = {
        table_name: @table_ame,
        key_schema: @key_schema,
        attribute_definitions: @attribute_definitions,
        provisioned_throughput: @provisioned_throughput
      }
      begin
        result = db.create_table(params)

        puts "DynamoDB Table: #{@table_name} Status: #{result.table_description.table_status}"
      rescue Aws::DynamoDB::Errors::ServiceError => error
        puts "Unable to create table: #{error.message}"
      end
    end
  end
end
