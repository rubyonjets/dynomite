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

    def to_params
      names, values, key_condition_expression, filter_expression, index = {}, {}, [], [], nil
      @args.each do |hash|
        hash.each do |k,v|
          names.merge!("##{k}" => k.to_s)
          values.merge!(":#{k}" => v)
          index = find_index(k) # Only supports the first index it finds
          if index
            key_condition_expression << "##{k} = :#{k}"
          else
            filter_expression << "##{k} = :#{k}"
          end
        end
      end

      params = {
        expression_attribute_names: names,
        expression_attribute_values: values,
        filter_expression: filter_expression.join(" AND "),
        key_condition_expression: key_condition_expression.join(" AND "),
        table_name: @source.table_name,
      }
      params[:index_name] = index.index_name if index

      params.reject { |k,v| v.empty? }
    end

    def all
      records.lazy.flat_map { |i| i }
    end

    # TODO: possiblet to hav multiple indexes with the same name.
    def find_index(attribute_name)
      @source.indexes.find do |i|
        i.key_schema.find do |key|
          attribute_name.to_s == key.attribute_name
        end
      end
    end

    def records
      params = to_params
      puts "params:"
      pp params
      if params[:key_condition_expression]
        perform(:query, params)
      else
        perform(:scan, params)
      end
    end
    private :records

    # meth: query or scan
    def perform(meth, params)
      Enumerator.new do |y|
        executer.call(meth, params).each do |resp|
          page = resp.items.map { |i| build_item(i) }
          y.yield(page, resp)
        end
      end
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

    def executer
      Executer.new
    end
    memoize :executer

    def each(&block)
      all.each(&block)
    end
  end
end
