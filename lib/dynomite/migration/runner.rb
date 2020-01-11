require "timeout"
require_relative "internal/migrate/create_schema_migrations_migration"
require_relative "internal/models/schema_migration"

class Dynomite::Migration
  class Runner
    include Dynomite::Item::WaiterMethods

    def initialize(options={})
      @options = options
    end

    def run
      puts "Running Dynomite migrations"
      ensure_schema_migrations_exist!

      Dynomite::Migration::FileInfo.all_files.each do |path|
        migrate(path)
      end
    end

    def migrate(path)
      load path
      file_info = FileInfo.new(path)

      migration = SchemaMigration.find_by(version: file_info.version)
      if migration
        if migration.status == "complete"
          return
        else
          action = with_timeout(message: "Timed out. You must respond within 60s.") do
            uncompleted_migration_prompt(file_info, migration)
          end
        end
      end

      case action
      when :skip
        return
      when :completed
        migration.status = "completed"
        migration.save
        return
      when :exit
        puts "Exiting"
        exit
      end

      # INSERT scheme_migrations table - in_progress
      unless migration
        pretty_path = file_info.path.sub(/^\.\//,'') # remove leading ./
        migration = SchemaMigration.new(version: file_info.version, status: "in_progress", path: pretty_path)
        migration.save
      end
      start_time = Time.now

      # Run actual migration
      migration_class = file_info.migration_class
      migration_class.new.up # wait happens within create_table or update_table

      # UPDATE scheme_migrations table - complete
      migration.status = "complete"
      migration.time_took = (Time.now - start_time).to_i
      migration.save
    end

    def with_timeout(options={}, &block)
      seconds = options[:seconds] || 60
      message = options[:message] || "Timed out after #{seconds}s."
      Timeout::timeout(seconds, &block)
    rescue Timeout::Error => e
      puts "#{e.class}: #{e.message}"
      puts message
      exit 1
    end

    def uncompleted_migration_prompt(file_info, migration)
      choice = nil
      until %w[s c e].include?(choice)
        puts(<<~EOL)
          The #{file_info.path} migration status is incomplete. Status: #{migration.status}
          This can happen and if it was interrupted by a CTRL-C.
          Please check the migration to help determine what to do next.

          Options:

              s - skip and continue. leaves schema_migrations item as-is
              c - mark as completed and continue. updates the schema_migrations item as completed.
              e - exit

          Choose an option (s/c/e):
        EOL
        choice = $stdin.gets.strip
      end

      map = {
        "s" => :skip,
        "c" => :completed,
        "e" => :exit,
      }
      map[choice]
    end

    def ensure_schema_migrations_exist!
      migration = CreateSchemaMigrationsMigration.new
      return if migration.table_exist?(SchemaMigration.table_name)
      migration.up
    end
  end
end
