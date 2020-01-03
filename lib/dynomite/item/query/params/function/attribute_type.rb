module Dynomite::Item::Query::Params::Function
  class AttributeType < Base
    def filter_expression
      filter_expression = []
      @query[:attribute_type].each do |attribute_type|
        path, type = attribute_type[:path], attribute_type[:type]
        path = normalize_expression_path(path)
        type = type_map(type)
        filter_expression << "attribute_type(#{path}, :#{type})"
      end
      filter_expression
    end

    def attribute_names
      paths = @query[:attribute_type].map { |attribute_type| attribute_type[:path] }
      build_attribute_names_with_dot_paths(paths)
    end

    def attribute_values
      values = {}
      @query[:attribute_type].each do |attribute_type|
        type = attribute_type[:type]
        type = type_map(type)
        values[":#{type}"] = type
      end
      values
    end
  end
end

