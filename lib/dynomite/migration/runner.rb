class Dynomite::Migration
  class Runner
    def initialize(options={})
      @options = options
    end

    def run
      puts "Running Dynomite migrations"
      Dynomite::SchemaMigration.ensure_table_exists!

      migration_files.each do |path|
        load path
        migration_class = get_migration_class(path)
        puts "migration_class #{migration_class}"
        migration_class.new.up
      end
    end

    def get_migration_class(path)
      filename = File.basename(path, '.rb')
      filename = filename.sub(/\d+[-_]/, '') # strip leading timestsamp
      filename.camelize.constantize
    end

    def migration_files
      Dir.glob("#{Dynomite.root}/dynamodb/migrate/*").to_a.sort
    end
  end
end
