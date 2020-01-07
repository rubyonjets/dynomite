class Dynomite::Item
  module Indexes
    extend Memoist

    def indexes
      global_secondary_indexes
    end

    def global_secondary_indexes
      resp = desc_table
      resp.table.global_secondary_indexes.select { |i| i.index_status == "ACTIVE" }
    end

    def desc_table
      db.describe_table(table_name: table_name)
    end
    memoize :desc_table
  end
end
