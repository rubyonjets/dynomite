class Dynomite::Item
  # Builds up the query with methods like where and eventually executes Query or Scan.
  class QueryBuilder
    include Enumerable

    def initialize(source)
      @source = source
      @args = []
    end

    def where(args)
      @args << args
      self
    end

    def to_params
      names, values, filter = {}, {}, []
      @args.each do |hash|
        hash.each do |k,v|
          names.merge!("##{k}" => k.to_s)
          values.merge!(":#{k}" => v)
          filter << "##{k} = :#{k}"
        end
      end

      {
        expression_attribute_names: names,
        expression_attribute_values: values,
        filter_expression: filter.join(' AND ')
      }
    end
  end
end
