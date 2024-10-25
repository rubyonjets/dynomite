require "zeitwerk"

module Dynomite
  class Autoloader
    class Inflector < Zeitwerk::Inflector
      def camelize(basename, _abspath)
        map = { cli: "CLI", version: "VERSION" }
        map[basename.to_sym] || super
      end
    end

    class << self
      def setup
        loader = Zeitwerk::Loader.new
        loader.inflector = Inflector.new
        lib = File.dirname(__dir__)
        loader.push_dir(lib)
        loader.ignore("#{lib}/jets/commands")
        loader.ignore("#{lib}/dynomite/migration/internal/*")
        loader.ignore("#{lib}/dynomite/migration/templates/*")
        loader.ignore("#{lib}/dynomite/reserved_words.rb")
        loader.do_not_eager_load("#{lib}/generators")
        loader.do_not_eager_load("#{lib}/dynomite/engine.rb")
        loader.setup
      end
    end
  end
end
