class Dynomite::Migration
  class Runner
    include Dynomite::Item::WaiterMethods

    def initialize(options={})
      @options = options
    end

    def run
      puts "Running Dynomite migrations"
      Dynomite::SchemaMigration.ensure_table_exists!

      Dynomite::Migration::FileInfo.all_files.each do |path|
        migrate(path)
      end
    end

    def migrate(path)
      load path
      file_info = FileInfo.new(path)

      migration = find_record(file_info)

      if migration
        if migration.status == "complete"
          return
        else
          Dynomite.logger.info(<<~EOL)
            The {file_info.path} migration is status is not complete. Status: #{migration.status}
            This can happen and was if the migration interupted by a CTRL-C.
            To continue, verify that the migration completed successfully and you can mark this migration completed with:

                dynomite complete #{file_info.path}

          EOL
          exit 1
        end
      end

      # INSERT scheme_migrations table - in_progress
      migration = Dynomite::SchemaMigration.new(version: file_info.version, status: "in_progress", path: file_info.path)
      migration.save
      start_time = Time.now

      migration_class = file_info.migration_class
      migration_class.new.up # wait happens within create_table or update_table

      # UPDATE scheme_migrations table - complete
      migration.status = "complete"
      migration.time_took = (Time.now - start_time).to_i
      migration.save
    end

    def find_record(file_info)
      # migration = Dynomite::SchemaMigration.where(version: file_info.version).first
      migration = Dynomite::SchemaMigration.scan
      migration.find { |i| i.version == file_info.version }
    end
  end
end
