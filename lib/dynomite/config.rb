module Dynomite
  class Config
    attr_accessor :logger, :log_level, :namespace_separator, :endpoint, :env,
                  :default_count_method, :warn_on_scan, :default_namespace, :discover_fields,
                  :migration, :undeclared_field_behavior, :default_field_type, :update_strategy
    def initialize
      @logger = Logger.new($stderr)
      @logger.formatter = ActiveSupport::Logger::SimpleFormatter.new
      @log_level = nil
      @namespace_separator = "_"
      @endpoint = ENV['DYNOMITE_ENDPOINT'] # allow to use local dynamodb
      @env = ActiveSupport::StringInquirer.new(ENV['DYNOMITE_ENV'] || "development")
      @default_count_method = :count # slow but accurate. :item_count is faster but can be stale by 6 hours
      @warn_on_scan = true
      @discover_fields = false
      @migration = ActiveSupport::OrderedOptions.new
      @undeclared_field_behavior = :warn # warn silent error allow
      # Not implemented: :datetime, :date, :float, :array, :set, :map
      # as we aws-sdk-dynamodb handles it via :infer
      @default_field_type = :infer # :string, :integer, :boolean, :time, :infer
      @update_strategy = :put_item # :put_item, :update_item
    end

    # User should use namespace. The default_namespace is only used internally so Jets can set it.
    # Makes it easy to set the namespace from the Jets project namespace.
    # Example:
    #
    # config/initializers/dynomite.rb
    #
    #     Dynomite.configure do |config|
    #       config.namespace = Jets.project_namespace # IE: demo-dev
    #     end
    #
    attr_writer :namespace
    def namespace
      ENV['DYNOMITE_NAMESPACE'] || @namespace || @default_namespace || 'dynomite'
    end
  end
end
