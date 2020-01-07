module Dynomite
  class SchemaMigration < Item
    table_name :schema_migrations

    column :version, :status, :time_took, :path

    class << self
      def ensure_table_exists!
        create_table unless table_exist?
      end

      def create_table
        puts "Creating #{table_name} table..."
        params = {
          table_name: table_name,
          key_schema: [{attribute_name: "id", key_type: "HASH"}],
          attribute_definitions: [{attribute_name: "id", attribute_type: "S"}],
          billing_mode: "PAY_PER_REQUEST",
        }
        show_request(params)
        resp = db.create_table(params)
        show_response(resp)
        waiter.wait(table_name)
      end

      def table_exist?
        db.describe_table(table_name: table_name)
        true
      rescue Aws::DynamoDB::Errors::ResourceNotFoundException
        false
      end
    end
  end
end
