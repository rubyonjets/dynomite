require 'logger'

module Dynomite
  module Core
    @@root = nil
    def root
      return @@root if @@root
      @@root = ENV['DYNOMITE_ROOT'] || ENV['JETS_ROOT'] || ENV['RAILS_ROOT'] || '.'
    end

    @@config = nil
    def config
      @@config ||= Config.new
    end

    def logger
      config.logger
    end
  end
end
