require "active_support/core_ext/string"

class DynamodbModel::Migration
  # jets generate migration posts --partition-key id:string
  class Generator
    include DynamodbModel::DbConfig

    attr_reader :table_name
    def initialize(table_name, options)
      @table_name = table_name.pluralize
      @options = options
    end

    def generate
      puts "Generating migration" unless @options[:quiet]
      return if @options[:noop]
      create_migration
    end

    def create_migration
      migration_path = "#{DynamodbModel.root}db/migrate/#{migration_file_name}.rb"
      dir = File.dirname(migration_path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      IO.write(migration_path, migration_code)
    end

    def migration_code
      # @table_name already set
      @migration_class_name = migration_file_name.classify
      @partition_key = @options[:partition_key]
      @sort_key = @options[:sort_key]
      @provisioned_throughput = @options[:provisioned_throughput] || 5
      template = IO.read(File.expand_path("../template.rb", __FILE__))
      result = ERB.new(template, nil, "-").result(binding)
    end

    def migration_file_name
      "#{@table_name}_migration"
    end

    def timestamp
      "timestamp"
    end
  end
end
