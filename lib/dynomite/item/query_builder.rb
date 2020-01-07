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

    def all
      Enumerator.new do |y|
        params = to_params
        params = { table_name: @source.table_name }.merge(params)
        # params[:limit] = 1
        resp = db.scan(params)
        puts "resp:"
        pp resp
        results = resp.items.map do |i|
          item = @source.new(i)
          item.new_record = false
          item
        end
        puts "results:"
        pp results

        y.yield(results, resp)
      end.lazy.flat_map { |i| i }
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
