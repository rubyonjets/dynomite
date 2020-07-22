module Dynomite
  class Query
    include Enumerable

    def initialize(item, params)
      @item = item
      @params = params
    end

    def <<(item)
      raise NotImplementedError
    end

    def inspect
      "#<Dynomite::Query [#{first(2).map(&:inspect).join(', ')}, ...]>"
    end

    def each(&block)
      run_query.each(&block)
    end

    def index_name(name)
      self.class.new(@item, @params.merge(index_name: name))
    end

    def where(attributes)
      raise "attributes.size == 1 only supported for now" if attributes.size != 1

      attr_name = attributes.keys.first
      attr_value = attributes[attr_name]

      name_key, value_key = "##{attr_name}_name", ":#{attr_name}_value"
      params = {
        expression_attribute_names: { name_key => attr_name },
        expression_attribute_values: { value_key => attr_value },
        key_condition_expression: "#{name_key} = #{value_key}",
      }

      self.class.new(@item, @params.merge(params))
    end

    private

    def run_query
      @query ||= @item.query(@params)
    end
  end
end
