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
      return @db_config if @db_config

      if defined?(Jets)
        config_path = "#{Jets.root}config/dynamodb.yml"
        env = Jets.env
      else
        config_path = ENV['DYNAMODB_MODEL_CONFIG'] || "./config/dynamodb.yml"
        env = ENV['DYNAMODB_MODEL_ENV'] || "development"
      end

      config = YAML.load(erb_result(config_path))
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

    def erb_result(path)
      template = IO.read(path)
      begin
        ERB.new(template, nil, "-").result(binding)
      rescue Exception => e
        puts e
        puts e.backtrace if ENV['DEBUG']

        # how to know where ERB stopped? - https://www.ruby-forum.com/topic/182051
        # syntax errors have the (erb):xxx info in e.message
        # undefined variables have (erb):xxx info in e.backtrac
        error_info = e.message.split("\n").grep(/\(erb\)/)[0]
        error_info ||= e.backtrace.grep(/\(erb\)/)[0]
        raise unless error_info # unable to find the (erb):xxx: error line
        line = error_info.split(':')[1].to_i
        puts "Error evaluating ERB template on line #{line.to_s.colorize(:red)} of: #{path.sub(/^\.\//, '').colorize(:green)}"

        template_lines = template.split("\n")
        context = 5 # lines of context
        top, bottom = [line-context-1, 0].max, line+context-1
        spacing = template_lines.size.to_s.size
        template_lines[top..bottom].each_with_index do |line_content, index|
          line_number = top+index+1
          if line_number == line
            printf("%#{spacing}d %s\n".colorize(:red), line_number, line_content)
          else
            printf("%#{spacing}d %s\n", line_number, line_content)
          end
        end
        exit 1 unless ENV['TEST']
      end
    end
  end
end
