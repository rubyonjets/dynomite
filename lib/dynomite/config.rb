module Dynomite
  class Config
    attr_accessor :logger, :table_namespace, :namespace_separator, :endpoint, :env
    def initialize
      @logger = Logger.new($stderr)
      @table_namespace = "dynomite"
      @namespace_separator = "_"
      @endpoint = ENV['DYNAMODB_ENDPOINT'] # allow to use local dynamodb
      @env = ActiveSupport::StringInquirer.new(ENV['DYNAMODB_ENV'] || "development")
    end
  end
end

# TODO: support this syntax
# Dynomite.configure do |config|
#   config.namespace = Jets.config.table_namespace
#   config.capacity_mode = :on_demand
# end
