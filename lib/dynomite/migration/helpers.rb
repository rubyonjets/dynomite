class Dynomite::Migration
  module Helpers
    def table_name_with_namespace(table_name)
      [Dynomite.config.namespace, table_name].reject {|s| s.nil? || s.empty?}.join(Dynomite.config.namespace_separator)
    end
  end
end
