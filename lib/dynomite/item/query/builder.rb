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
          page = resp.items.map { |i| build_item(i) }
          y.yield(page, resp)
        end
      end
      enumerator.lazy.flat_map { |i| i }
    end

    def build_item(i)
      item = @source.new(i)
      item.new_record = false
      item
    end

    # Enumerable provides .first but does not provide .last
    def last
      all.to_a.last
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

      params = {
        table_name: @source.table_name,
        expression_attribute_names: names,
        expression_attribute_values: values,
        filter_expression: filter.join(' AND ')
      }
      params.reject { |k,v| v.empty? }
    end

    def executer
      Executer.new
    end
    memoize :executer

    def each(&block)
      all.each(&block)
    end
  end
end
