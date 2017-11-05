module DynamodbModel
  class Migration
    autoload :Dsl, "dynamodb_model/migration/dsl"
    autoload :Generator, "dynamodb_model/migration/generator"

    def up
      puts "Should defined an up method for your migration: #{self.class.name}"
    end

    def create_table(table_name, &block)
      execute_dsl(:create_table, table_name, &block)
    end

    def update_table(table_name, &block)
      execute_dsl(:update_table, table_name, &block)
    end

  private
    def execute_dsl(method_name, table_name)
      dsl = Dsl.new(method_name, table_name)
      yield(dsl)
      dsl.params
      # executor = DslExecutor.new(method_name, params)
      # executor.run
      # dsl.execute(method_name)
    end
  end
end
