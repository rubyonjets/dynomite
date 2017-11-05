module DynamodbModel
  class Migration
    autoload :Dsl, "dynamodb_model/migration/dsl"
    autoload :Generator, "dynamodb_model/migration/generator"

    def up
      puts "Should defined an up method for your migration: #{self.class.name}"
    end

    def create_table(table_name)
      execute_dsl(:create_table, table_name)
    end

    def update_table(table_name)
      execute_dsl(:update_table, table_name)
    end

  private
    def execute_dsl(method_name, table_name)
      dsl = Dsl.new(method_name, table_name)
      yield(dsl)
      dsl.execute
    end
  end
end
