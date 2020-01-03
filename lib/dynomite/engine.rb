module Dynomite
  class Engine < ::Jets::Engine
    config.after_initialize do
      Dynomite.config.default_namespace = Jets.project_namespace # IE: demo-dev
      Dynomite.config.migration.deletion_protection_enabled = Jets.env.production?

      # Discover all the fields for all the models from attribute_definitions
      # and create field methods. Has to be done after_initialize because
      # need model names for the table_name.
      quiet_dynamodb_logging do
        Dynomite::Item.descendants.each do |klass|
          klass.discover_fields!
        end if Dynomite.config.discover_fields
      end
    end

    def self.default_log_level
      # Note: On AWS Lambda, ARGV[0] is nil
      if ARGV[0]&.include?("dynamodb") # IE: dynamodb:migrate dynamodb:seed
        :info
      else
        Jets.env.development? ? :debug : :info
      end
    end

    def self.quiet_dynamodb_logging
      if ENV['DYNOMITE_DEBUG']
        # If in debug mode, then leave the log level alone which is debug in development
        # This shows the describe_table calls on jets console bootup
        Dynomite.config.log_level = default_log_level
      else
        # Otherwise, set the log level to info temporarily to quiet the describe_table calls
        # Then reset the log level back to the user's configured log level.
        user_log_level = Dynomite.config.log_level
        Dynomite.config.log_level = :info
      end

      yield

      Dynomite::Item.client = nil # reset client. Need to reset the client since it's cached
      # Go back to the user's configured log level or the default log level if user did not set it.
      Dynomite.config.log_level = user_log_level || default_log_level
    end
  end
end
