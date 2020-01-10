module Dynomite::Item::Query::Write
  class Base
    include Dynomite::Client

    def self.call(model, options={})
      new(model, options).call
    end

    def initialize(model, options)
      @model, @options = model, options
    end
  end
end
