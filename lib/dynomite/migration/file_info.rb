class Dynomite::Migration
  class FileInfo
    attr_reader :path
    def initialize(path)
      @path = path
    end

    def pretty_path
      @path.sub(/^\.\//,'') # remove leading ./
    end

    def migration_class
      filename = File.basename(@path, '.rb')
      filename = filename.sub(/\d+[-_]/, '') # strip leading timestsamp
      filename.camelize.constantize
    end

    def version
      filename = File.basename(@path, '.rb')
      md = filename.match(/(\d+)[-_]/)
      md[1].to_i
    end

    def self.all_files
      Dir.glob("#{Dynomite.root}/dynamodb/migrate/*").to_a.sort
    end
  end
end
