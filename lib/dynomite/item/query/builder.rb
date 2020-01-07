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

    def to_params(meth)
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
      }

      # TODO: use key condition and filter expression at the same time
      if meth == :query
        params[:key_condition_expression] = filter.join(' AND ')
      else
        params[:filter_expression] = filter.join(' AND ')
      end

      params.reject { |k,v| v.empty? }
    end

    def all
      records.lazy.flat_map { |i| i }
    end

    def records
      if index_name
        params = to_params(:query)
        perform(:query, params.merge(index_name: index_name))
      else
        params = to_params(:scan)
        perform(:scan, params)
      end
    end
    private :records

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

    # TODO: There could be multiple indexes with the same name and also indexes where there's a sort key...
    def index_name
      index = @source.indexes.find do |i|
        i.key_schema.find do |key|
          args_hash.keys.map(&:to_s).include?(key.attribute_name)
        end
      end
      index.index_name if index
    end

    def args_hash
      @args.inject({}) do |result, hash|
        result.merge(hash)
      end
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
