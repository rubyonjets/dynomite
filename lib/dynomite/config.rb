module Dynomite
  class Config
    attr_accessor :logger, :namespace, :namespace_separator, :endpoint, :env
    def initialize
      @logger = Logger.new($stderr)
      @namespace = "dynomite"
      @namespace_separator = "_"
      @endpoint = ENV['DYNAMODB_ENDPOINT'] # allow to use local dynamodb
      @env = ActiveSupport::StringInquirer.new(ENV['DYNAMODB_ENV'] || "development")
    end
  end
end
