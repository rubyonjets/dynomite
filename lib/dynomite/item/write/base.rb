module Dynomite::Item::Write
  class Base
    include Dynomite::Client

    # The attributes are in model.attrs and are held by reference
    # The options are the client.delete_item or client.put_item options.
    def self.call(model, options={})
      new(model, options).call
    end

    def initialize(model, options={})
      @model, @options = model, options
    end
  end
end
