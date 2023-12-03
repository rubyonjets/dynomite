class Dynomite::Item::Query::Params
  module Helpers
    # Important to reset relation index for each relation chain so that
    # attribute name references are correct.
    # Using `with_where_groups` when interating ensures index is reset.
    def with_where_groups
      @relation.index = 0
      @relation.query[:where].each do |where_group|
        yield(where_group)
      end
    end

    def query
      @relation.query
    end

    # Certain queries require a scan, so we can't use the key condition
    def scan_required?(index)
      return true if index.nil? # first check
      return true if query[:force_scan]
      return true if disable_index_for_any_or?
      return true if disable_index_for_not?(index)
      return true if disable_index_for_consistent_read?(index)

      all_where_fields.find do |full_field|
        field, operator = full_field.split('.')
        index.fields.include?(field) && !operator.nil?
      end
    end

    # Always run scan when any or in chain
    # For dynomite, `or` expressions will always result in a scan operation.
    # This is because `key_condition_expression` does not support OR expressions.
    # Nor does it make sense to use query with an index in the first pass with
    # `key_condition_expression` and use `filter_expression` in the second pass.
    # The `key_condition_expression` and `filter_expression` are AND with each other,
    # so it would not be possible to do an OR without a scan.
    def disable_index_for_any_or?
      disable = query[:where].any? { |where_group| where_group.or? }
      logger.info "Disabling index since an or was used" if disable && ENV['DYNOMITE_DEBUG']
      disable
    end

    def disable_index_for_not?(index)
      disable = query[:where].any? do |where_group|
        x = where_group.fields & index.fields
        !x.empty? && where_group.not?
      end
      logger.info "Disabling index since a not was used for the index" if disable && ENV['DYNOMITE_DEBUG']
      disable
    end

    def disable_index_for_consistent_read?(index)
      if query.key?(:consistent_read)
        if index.nil?
          true # must use scan for consistent read
        elsif index.primary?
          false # can use index for consistent ready for the primary key index only
        else
          true # must use scan for GSI indexes
        end
      else
        false
      end
    end

    # full field names with operator
    def all_where_fields
      query[:where].map(&:keys).flatten.map(&:to_s)
    end

    def all_where_field_names
      all_where_fields.map { |k| k.split('.').first }
    end

    def normalize_expression_path(path)
      path.split('.').map do |field|
        field.starts_with?('#') ? field : field.prepend('#')
      end.join('.')
    end

    def normalize_project_expression(args)
      project_expression = []
      args.map do |element|
        if element.is_a?(String)
          project_expression += element.split(',').map(&:strip)
        else
          project_expression << element.to_s
        end
      end
      project_expression
    end
  end
end
