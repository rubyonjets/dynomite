require "timeout"
require_relative "internal/migrate/create_schema_migrations"
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
      clear_error_schema_migrations! if ENV['CLEAR_ERRORS']
      check_for_migration_errors!
      Dynomite::Migration::FileInfo.all_files.each do |path|
        migrate(path)
      end
    end

    def migrate(path)
      # load migration class definition
      #   CreatePosts#up (up is called below)
      file_info = FileInfo.new(path)

      schema_migration = SchemaMigration.find_by(version: file_info.version)
      if schema_migration
        teriminal_statuses = %w[complete error]
        if teriminal_statuses.include?(schema_migration.status)
          return
        else
          action = with_timeout(message: "Timed out. You must respond within 60s.") do
            uncompleted_migration_prompt(file_info, schema_migration)
          end
        end
      end

      case action
      when :skip
        return
      when :delete
        schema_migration.delete
      when :completed
        schema_migration.status = "completed"
        schema_migration.save
        return
      when :exit
        puts "Exiting"
        exit
      end

      puts "Running migration: #{file_info.pretty_path}"
      load path

      # INSERT schema_migration table - in_progress
      unless schema_migration
        schema_migration = SchemaMigration.new(version: file_info.version, status: "in_progress", path: file_info.pretty_path)
        schema_migration.save
      end
      start_time = Time.now

      # Run actual migration
      migration_class = file_info.migration_class
      error_message = nil
      begin
        # Runs migration up command. Example:
        #   CreatePosts#up
        #   Migration#create_table
        #   Migration#execute (wait happens here)
        migration_class.new.up # wait happens within create_table or update_table
      rescue Aws::DynamoDB::Errors::ServiceError => error
        puts "Unable to #{@method_name.to_s.gsub('_',' ')}: #{error.message}".color(:red)
        error_message = error.message
      end

      # UPDATE schema_migrations table - complete status
      if error_message
        schema_migration.status = "error"
        schema_migration.error_message = error_message
      else
        schema_migration.status = "complete"
      end

      schema_migration.time_took = (Time.now - start_time).to_i
      schema_migration.save
      # schema_migration.delete # HACK
      puts "Time took: #{pretty_time_took(schema_migration.time_took)}"
      exit 1 if error_message # otherwise continue to next migration file
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

    def uncompleted_migration_prompt(file_info, schema_migration)
      choice = nil
      until %w[s d c e].include?(choice)
        puts(<<~EOL)
          The #{file_info.pretty_path} migration status is incomplete. Status: #{schema_migration.status}
          This can happen and if it was interrupted by a CTRL-C.
          Please check the migration to help determine what to do next.

          Options:

              s - skip and continue. leaves schema_migrations item as-is
              d - delete and continue. deletes the schema_migrations item
              c - mark as successful completed and continue. updates the schema_migrations item as completed.
              e - exit

          EOL
          print "Choose an option (s/d/c/e): "
        choice = $stdin.gets.strip
      end

      map = {
        "s" => :skip,
        "d" => :delete,
        "c" => :completed,
        "e" => :exit,
      }
      map[choice]
    end

    def ensure_schema_migrations_exist!
      migration = CreateSchemaMigrations.new
      return if migration.table_exist?(SchemaMigration.table_name)
      puts "Creating #{SchemaMigration.table_name} table for the first time"
      migration.up
    end

    def clear_error_schema_migrations!
      SchemaMigration.warn_on_scan(false).where(status: "error").each do |schema_migration|
        schema_migration.delete
        puts "Deleted error schema_migration: #{schema_migration.path}"
      end
    end

    def check_for_migration_errors!
      errors = SchemaMigration.warn_on_scan(false).where(status: "error")
      errors_info = SchemaMigration.warn_on_scan(false).where(status: "error").map do |schema_migration|
        "    #{schema_migration.path} - #{schema_migration.error_message}"
      end.join("\n")
      if errors.count > 0
        puts <<~EOL
          Found error migrations. Please review the migration erors fix before continuing.
          You can clear them out manually by deleting them from the #{SchemaMigration.table_name} table.

          #{errors_info}

          You can also clear them with the following command:

              CLEAR_ERRORS=1 jets dynamodb:migrate

        EOL
        exit 1
      end
    end

    # http://stackoverflow.com/questions/4175733/convert-duration-to-hoursminutesseconds-or-similar-in-rails-3-or-ruby
    def pretty_time_took(total_seconds)
      minutes = (total_seconds / 60) % 60
      seconds = total_seconds % 60
      if total_seconds < 60
        "#{seconds.to_i}s"
      else
        "#{minutes.to_i}m #{seconds.to_i}s"
      end
    end
  end
end
