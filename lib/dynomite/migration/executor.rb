class Dynomite::Migration
  class Executor
    include Dynomite::DbConfig

    # Examples:
    #  Executor.new(:create_table, params) or
    #  Executor.new(:update_table, params)
    #
    # The params are generated frmo the dsl.params
    attr_accessor :table_name
    def initialize(table_name, method_name, params)
      @table_name = table_name
      @method_name = method_name # create_table or update_table
      @params = params
    end

    def run
      begin
        # Examples:
        #   result = db.create_table(@params)
        #   result = db.update_table(@params)

        # Leaving this verbose output in here until this DSL is more hardened to help debug
        unless ENV['DYNOMITE_ENV'] == 'test'
          puts "Calling #{@method_name} with params:"
          pp @params
        end

        return if ENV['DYNOMITE_DRY'] # dry run flag
        result = db.send(@method_name, @params)

        puts "DynamoDB Table: #{@table_name} Status: #{result.table_description.table_status}"
      rescue Aws::DynamoDB::Errors::ServiceError => error
        puts "Unable to #{@method_name.to_s.gsub('_',' ')}: #{error.message}".color(:red)
      end
    end
  end
end
