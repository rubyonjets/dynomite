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
      params = to_params
      params = { table_name: @source.table_name }.merge(params)
      resp = db.scan(params)
      resp.items.map {|i| @source.new(i.merge(new_record: false)) }
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
