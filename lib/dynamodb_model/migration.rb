module DynamodbModel
  class Migration
    autoload :Dsl, "dynamodb_model/migration/dsl"
    autoload :Generator, "dynamodb_model/migration/generator"

    class << self
      def up
        puts "Running up migration for #{self.class.name}"
      end

      def create_table(table_name)
        dsl = Dsl.new(table_name)
        yield(dsl)
        # dsl.execute # unsure when to call this
      end
    end
  end
end
