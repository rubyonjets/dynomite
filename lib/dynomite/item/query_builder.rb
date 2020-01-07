class Dynomite::Item
  # Builds up the query with methods like where and eventually executes Query or Scan.
  class QueryBuilder
    include Dynomite::Client
    include Enumerable

    def initialize(source)
      @source = source
      @args = []
    end

    def where(args)
      @args << args
      self
    end

    def scan(params)
      params = { table_name: @source.table_name }.merge(params)
      params[:limit] = 1

      results = []
      last_evaluated_key = :start
      while last_evaluated_key
        if last_evaluated_key && last_evaluated_key != :start
          params[:exclusive_start_key] = last_evaluated_key
        end
        resp = db.scan(params)
        page = resp.items.map do |i|
          item = @source.new(i)
          item.new_record = false
          item
        end
        results += page
        last_evaluated_key = resp.last_evaluated_key
      end
      results
    end

    def all
      params = to_params
      Enumerator.new do |y|
        page = scan(params)
        y.yield(page)
      end.lazy.flat_map { |i| i }
      #   y.yield(page, resp)
      # end.lazy.flat_map { |i| i }
    end

    def each(&block)
      all.each(&block)
    end

    def execute
      params = to_params
      puts "@source.table_name #{@source.table_name}"
      puts "params #{params}"
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
