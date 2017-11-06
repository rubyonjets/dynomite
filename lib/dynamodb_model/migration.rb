module DynamodbModel
  class Migration
    autoload :Dsl, "dynamodb_model/migration/dsl"
    autoload :Generator, "dynamodb_model/migration/generator"
    autoload :Executor, "dynamodb_model/migration/executor"

    def up
      puts "Should defined an up method for your migration: #{self.class.name}"
    end

    def create_table(table_name, &block)
      execute_with_dsl_params(table_name, :create_table, &block)
    end

    def update_table(table_name, &block)
      execute_with_dsl_params(table_name, :update_table, &block)
    end

  private
    def execute_with_dsl_params(table_name, method_name, &block)
      dsl = Dsl.new(method_name, table_name, &block)
      params = dsl.params
      executor = Executor.new(table_name, method_name, params)
      executor.run
    end
  end
end
