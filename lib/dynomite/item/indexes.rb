class Dynomite::Item
  module Indexes
    extend Memoist

    # Sorted by indexes with combo partition and sort keys first so they take priority for
    # Indexes::Finder#find
    def indexes
      global_secondary_indexes.map { |i| Index.new(i) }.sort_by { |i| i.fields.size * -1 }
    end

    def global_secondary_indexes
      resp = desc_table
      resp.table.global_secondary_indexes.to_a.select { |i| i.index_status == "ACTIVE" }
    end

    def desc_table
      db.describe_table(table_name: table_name)
    end
    memoize :desc_table
  end
end
