class Dynomite::Item
  module Indexes
    def index_names
      indexes.map(&:index_name)
    end

    # Sorted by indexes with composite keys with partition and sort keys first
    # so they take priority for Indexes::Finder#find
    def indexes
      lsi = local_secondary_indexes.map { |i| Index.new(i) }.sort_by { |i| i.fields.size * -1 }
      gsi = global_secondary_indexes.map { |i| Index.new(i) }.sort_by { |i| i.fields.size * -1 }
      lsi + gsi
    end

    def local_secondary_indexes
      table = desc_table(table_name)
      table.local_secondary_indexes.to_a
    end

    def global_secondary_indexes
      table = desc_table(table_name)
      table.global_secondary_indexes.to_a.select { |i| i.index_status == "ACTIVE" }
    end
  end
end
