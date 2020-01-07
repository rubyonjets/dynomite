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
      return if @options[:noop]
      create_migration
    end

    def create_migration
      FileUtils.mkdir_p(File.dirname(migration_path))
      IO.write(migration_path, migration_code)
      puts "Migration file created: #{migration_path}\nTo run:\n\n"
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
        provisioned_throughput: @options[:provisioned_throughput] || 5,
      )
    end

    def action
      action = @options[:action] || conventional_action
      if %w[create_table update_table].include?(action)
        action
      else
        "create_table" # fallback
      end
    end

    def conventional_action
      @migration_name.include?("update") ? "update_table" : "create_table"
    end

    def table_name
      @options[:table_name] || conventional_table_name || "TABLE_NAME"
    end

    # create_posts => posts
    # update_posts => posts
    def conventional_table_name
      @migration_name.sub(/^(create|update)_/, '')
    end

    def migration_class_name
      "#{@migration_name}_migration".classify # doesnt include timestamp
    end

    def migration_path
      "#{Dynomite.root}/dynamodb/migrate/#{timestamp}-#{@migration_name}_migration.rb"
    end

    def timestamp
      @timestamp ||= Time.now.strftime("%Y%m%d%H%M%S")
    end
  end
end
