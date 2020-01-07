class Dynomite::Migration
  class FileInfo
    def initialize(path)
      @path = path
    end

    def migration_class
      filename = File.basename(@path, '.rb')
      filename = filename.sub(/\d+[-_]/, '') # strip leading timestsamp
      filename.camelize.constantize
    end

    def version
      filename = File.basename(@path, '.rb')
      md = filename.match(/(\d+)[-_]/)
      md[1]
    end

    def self.all_files
      Dir.glob("#{Dynomite.root}/dynamodb/migrate/*").to_a.sort
    end
  end
end
