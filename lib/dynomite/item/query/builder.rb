module Dynomite::Item::Query
  # Builds up the query with methods like where and eventually executes Query or Scan.
  class Builder
    extend Memoist
    include Enumerable

    def initialize(source)
      @source = source
      @args = []
    end

    def where(args)
      @args << args
      self
    end

    def all
      params = to_params
      enumerator = Enumerator.new do |y|
        executer.scan(params).each do |resp|
          page = resp.items.map do |i|
            item = @source.new(i)
            item.new_record = false
            item
          end
          y.yield(page, resp)
        end
      end
      enumerator.lazy.flat_map { |i| i }
    end

    def executer
      Executer.new
    end
    memoize :executer

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
        table_name: @source.table_name,
        expression_attribute_names: names,
        expression_attribute_values: values,
        filter_expression: filter.join(' AND ')
      }
    end

    def each(&block)
      all.each(&block)
    end
  end
end
