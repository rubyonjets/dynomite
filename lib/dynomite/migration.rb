module Dynomite
  class Migration
    autoload :Dsl, "dynomite/migration/dsl"
    autoload :Generator, "dynomite/migration/generator"
    autoload :Executor, "dynomite/migration/executor"

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
