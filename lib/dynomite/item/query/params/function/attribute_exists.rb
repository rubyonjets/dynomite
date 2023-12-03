module Dynomite::Item::Query::Params::Function
  class AttributeExists < Base
    def filter_expression
      filter_expression = []
      @query[:attribute_exists].each do |path|
        path = normalize_expression_path(path)
        filter_expression << "attribute_exists(#{path})"
      end
      @query[:attribute_not_exists].each do |path|
        path = normalize_expression_path(path)
        filter_expression << "attribute_not_exists(#{path})"
      end
      filter_expression
    end

    def attribute_names
      paths = @query[:attribute_exists] + @query[:attribute_not_exists]
      build_attribute_names_with_dot_paths(paths)
    end
  end
end
