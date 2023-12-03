class Dynomite::Item::Query::Params
  class KeyCondition < Base
    def initialize(relation, index, partition_key_field, sort_key_field)
      @relation, @index, @partition_key_field, @sort_key_field = relation, index, partition_key_field, sort_key_field
      @expressions = []
    end

    def expression
      build
      join_expressions
    end

    def build
      with_where_groups do |where_group|
        expression = where_group.build_compare_expression_if do |field|
          @index.fields.include?(field)
        end
        next unless expression
        @expressions << expression
      end
    end
    memoize :build

    def full_primary_key_in_query?
      field_names = all_where_field_names
      if @sort_key_field
        field_names.include?(@sort_key_field) && field_names.include?(@partition_key_field)
      else
        field_names.include?(@partition_key_field)
      end
    end
  end
end

