module DynamodbModel
  autoload :Dsl, "dynamodb_model/migration/dsl"

  class Migration
    Dsl.db = "test"

    class << self
      def up
        puts "Running up migration for #{self.class.name}"
      end

      def create_table(table_name)
        dsl = Dsl.new(table_name)
        yield(dsl)
        dsl.execute
      end
    end
  end
end
