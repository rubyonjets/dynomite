module Dynomite::Item::Query::Params::Function
  class BeginsWith < Base
    def filter_expression
      filter_expression = []
      @query[query_key].each do |begins_with|
        path, substr = begins_with[:path], begins_with[:substr]
        path = normalize_expression_path(path)
        filter_expression << "#{query_key}(#{path}, :#{substr})"
      end
      filter_expression
    end

    def attribute_names
      paths = @query[query_key].map { |begins_with| begins_with[:path] }
      build_attribute_names_with_dot_paths(paths)
    end

    def attribute_values
      values = {}
      @query[query_key].each do |begins_with|
        path, substr = begins_with[:path], begins_with[:substr]
        values[":#{substr}"] = substr
      end
      values
    end

    # interface method so Contains < BeginsWith can override
    def query_key
      :begins_with # must be a symbol
    end
  end
end
