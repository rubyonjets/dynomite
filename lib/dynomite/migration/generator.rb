require "active_support/core_ext/string"

class Dynomite::Migration
  # jets dynamodb:generate posts --partition-key id:string
  class Generator
    attr_reader :migration_name, :table_name
    def initialize(migration_name, options)
      @migration_name = migration_name
      @options = options
    end

    def generate
      puts "Generating migration" unless @options[:quiet]
      return if ENV['NOOP']
      create_migration
    end

    def create_migration
      FileUtils.mkdir_p(File.dirname(migration_path))
      IO.write(migration_path, migration_code)
      pretty_migration_path = migration_path.sub(/^\.\//,'') # remove leading ./
      puts "Migration file created: #{pretty_migration_path}\nTo run:\n\n"
      command = File.basename($0)
      if command == "jets"
        puts "    #{command} dynamodb:migrate"
      else
        puts "    #{command} migrate"
      end
      puts
    end

    def migration_code
      path = File.expand_path("../templates/#{action}.rb", __FILE__)
      Dynomite::Erb.result(path,
        migration_class_name: migration_class_name,
        table_name: table_name,
        partition_key: @options[:partition_key],
        sort_key: @options[:sort_key],
        provisioned_throughput: @options[:provisioned_throughput] || 5
      )
    end

    def action
      # optoins[:table_action] is old and deprecated
      action = @options[:action] || @options[:table_action] || conventional_action
      case action
      when /create/
        "create_table"
      when /delete/
        "delete_table"
      else
        "update_table" # default and fallback
      end
    end

    def conventional_action
      @migration_name.split("_").first
    end

    def table_name
      @options[:table_name] || conventional_table_name || "TABLE_NAME"
    end

    # create_posts => posts
    # update_posts => posts
    def conventional_table_name
      @migration_name.sub(/^(create|update|delete)_/, '')
    end

    def migration_class_name
      "#{@migration_name}".camelize # doesnt include timestamp
    end

    def migration_path
      "#{Dynomite.root}/dynamodb/migrate/#{timestamp}-#{@migration_name}.rb"
    end

    def timestamp
      @timestamp ||= Time.now.strftime("%Y%m%d%H%M%S")
    end
  end
end
