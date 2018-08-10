require "aws-sdk-dynamodb"
require 'fileutils'
require 'erb'
require 'yaml'

module Dynomite::DbConfig
  def self.included(base)
    base.extend(ClassMethods)
  end

  def db
    self.class.db
  end

  # NOTE: Class including Dynomite::DbConfig is required to have table_name method defined
  def namespaced_table_name
    [self.class.table_namespace, table_name].reject {|s| s.nil? || s.empty?}.join('-')
  end

  module ClassMethods
    @@db = nil
    def db
      return @@db if @@db

      config = db_config
      endpoint = ENV['DYNAMODB_ENDPOINT'] || config['endpoint']
      check_dynamodb_local!(endpoint)

      Aws.config.update(endpoint: endpoint) if endpoint
      @@db ||= Aws::DynamoDB::Client.new
    end

    # When endoint has been configured to point at dynamodb local: localhost:8000
    # check if port 8000 is listening and timeout quickly. Or else it takes a
    # for DynamoDB local to time out, about 10 seconds...
    # This wastes less of the users time.
    def check_dynamodb_local!(endpoint)
      return unless endpoint && endpoint.include?("8000")

      open = port_open?("127.0.0.1", 8000, 0.2)
      unless open
        raise "You have configured your app to use DynamoDB local, but it is not running.  Please start DynamoDB local. Example: brew cask install dynamodb-local && dynamodb-local"
      end
    end

    # Thanks: https://gist.github.com/ashrithr/5305786
    def port_open?(ip, port, seconds=1)
      # => checks if a port is open or not
      Timeout::timeout(seconds) do
        begin
          TCPSocket.new(ip, port).close
          true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
          false
        end
      end
    rescue Timeout::Error
      false
    end

    # useful for specs
    def db=(db)
      @@db = db
    end

    def db_config
      return @db_config if @db_config

      if defined?(Jets)
        config_path = "#{Jets.root}config/dynamodb.yml"
        env = Jets.env
      else
        config_path = ENV['DYNOMITE_CONFIG'] || "./config/dynamodb.yml"
        env = ENV['DYNOMITE_ENV'] || "development"
      end

      config = YAML.load(Dynomite::Erb.result(config_path))
      @db_config ||= config[env] || {}
    end

    def table_namespace(*args)
      case args.size
      when 0
        get_table_namespace
      when 1
        set_table_namespace(args[0])
      end
    end

    def get_table_namespace
      return @table_namespace if defined?(@table_namespace)

      config = db_config
      @table_namespace = config['table_namespace']
    end

    def set_table_namespace(value)
      @table_namespace = value
    end
  end
end
