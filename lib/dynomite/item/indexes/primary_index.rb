module Dynomite::Item::Indexes
  class PrimaryIndex
    attr_reader :fields
    def initialize(fields)
      @fields = fields
    end

    # primary index is the table itself
    # no name. LSI and GSI have names.
    def index_name
      "primary_key (fields: #{fields.join(", ")})"
    end

    def primary?
      true
    end
  end
end