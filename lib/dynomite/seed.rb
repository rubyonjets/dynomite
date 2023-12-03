module Dynomite
  class Seed
    def initialize(options={})
      @options = options
    end

    def run
      file = "dynamodb/seeds.rb"
      load(file) if File.exist?(file)
    end
  end
end
