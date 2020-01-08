module Dynomite::Item::Query
  # Builds up the query with methods like where and eventually executes Query or Scan.
  class Builder
    extend Memoist
    include Enumerable

    def initialize(source)
      @source = source
      @query = {}
      @index_finder = Dynomite::Item::Indexes::Finder.new(@source, @query)
    end

    def where(args)
      @query[:where] ||= []
      @query[:where] << args
      self
    end

     # data has partition_key and sort_key
    def index(name, data={})
      @query[:index] = {index_name: name}.merge(data)
      self
    end

    def to_params
      names, values, key_condition_expression, filter_expression = {}, {}, [], []
      index = @index_finder.find

      @query[:where].each do |hash|
        hash.each do |field, value|
          field = field.to_s
          names.merge!("##{field}" => field)
          values.merge!(":#{field}" => value)
          unless index && index.fields.include?(field)
            filter_expression << "##{field} = :#{field}"
          end
        end
      end

      if index
        index.fields.each do |field|
          key_condition_expression << "##{field} = :#{field}"
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

      params.reject { |k,v| v.blank? }
    end

    def find_index_name(attribute_name)
      attribute_name = attribute_name.to_s
      if @query[:index]
        data = @query[:index]
        if attribute_name == data[:partition_key] # TODO: figure out how to use sort_key?
          data[:index_name]
        end
      else
        index = @index_finder.find(attribute_name) # Only supports the first index it finds
        index.index_name if index
      end
    end

    def all
      records.lazy.flat_map { |i| i }
    end

    def records
      params = to_params
      if ENV['DYNOMITE_DEBUG_PARAMS']
        puts "params:"
        pp params
      end
      if params[:index_name]
        perform(:query, params)
      else
        Dynomite.logger.info("WARN: Scan operations are slow. Considering using an index.")
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
