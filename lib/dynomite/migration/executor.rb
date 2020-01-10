class Dynomite::Migration
  class Executor
    include Dynomite::Client

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
        #   resp = db.create_table(@params)
        #   resp = db.update_table(@params)
        return if ENV['DYNOMITE_DRY'] # dry run flag

        show_request(@params)
        resp = db.send(@method_name, @params)
        show_response(resp)
        puts "DynamoDB Table: #{@table_name} Status: #{resp.table_description.table_status}"
      rescue Aws::DynamoDB::Errors::ServiceError => error
        puts "Unable to #{@method_name.to_s.gsub('_',' ')}: #{error.message}".color(:red)
      end
    end
  end
end
