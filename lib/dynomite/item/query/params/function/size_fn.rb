module Dynomite::Item::Query::Params::Function
  class SizeFn < Base
    include Dynomite::Item::Query::Relation::ComparisionMap

    # Product.size_fn("category.gt", 100)
    def filter_expression
      filter_expression = []
      @query[:size_fn].each_with_index do |size_fn, index|
        path, size = size_fn[:path], size_fn[:size]
        elements = path.split('.')
        operator = elements.pop # remove last element
        path = elements.join('.') # path no longer has operator
        comparision = comparision_for(operator)
        path = normalize_expression_path(path)
        filter_expression << "size(#{path}) #{comparision} :size_value#{index}"
      end
      filter_expression
    end

    def attribute_names
      paths = @query[:size_fn].map do |size_fn|
        path = size_fn[:path]
        path.split('.')[0..-2].join('.') # remove last element: comparision operator
      end
      build_attribute_names_with_dot_paths(paths)
    end

    def attribute_values
      values = {}
      @query[:size_fn].each_with_index do |size_fn, index|
        size = size_fn[:size]
        values[":size_value#{index}"] = size
      end
      values
    end
  end
end
