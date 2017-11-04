require "aws-sdk-dynamodb"
require 'fileutils'
require 'erb'
require 'yaml'

module DynamodbModel::DbConfig
  def self.included(base)
    base.extend(ClassMethods)
  end

  def db
    self.class.db
  end

  module ClassMethods
    @@db = nil
    def db
      return @@db if @@db

      config = db_config
      endpoint = ENV['DYNAMODB_ENDPOINT'] || config['endpoint']
      Aws.config.update(endpoint: endpoint) if endpoint

      @@db ||= Aws::DynamoDB::Client.new
    end

    # useful for specs
    def db=(db)
      @@db = db
    end

    def db_config
      if defined?(Jets)
        YAML.load_file("#{Jets.root}config/dynamodb.yml")[Jets.env] || {}
      else
        config_path = ENV['DYNAMODB_MODEL_CONFIG'] || "./config/dynamodb.yml"
        env = ENV['DYNAMODB_MODEL_ENV'] || "development"
        YAML.load_file(config_path)[env] || {}
      end
    end

    @table_namespace = nil
    def table_namespace
      return @table_namespace if @table_namespace

      config = db_config
      @table_namespace = config['table_namespace']
    end
  end
end
