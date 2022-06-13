module Dynomite::Item::Indexes
  class PrimaryIndex
    def initialize(field)
      @field = field
    end

    attr_reader :field

    def index_name
      nil
    end

    def fields
      Array(field)
    end
  end
end