module Dynomite
  class Seed
    def initialize(options={})
      @options = options
      Dynomite.config.log_level = :info unless ENV['DYNOMITE_DEBUG']
    end

    def run
      file = "dynamodb/seeds.rb"
      load(file) if File.exist?(file)
    end
  end
end
