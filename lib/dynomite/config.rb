module Dynomite
  class Config
    attr_accessor :logger
    def initialize
      @logger = Logger.new($stderr)
    end
  end
end
