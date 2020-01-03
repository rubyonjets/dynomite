module Dynomite::Item::Write
  class UpdateItem < Base
    def initialize(model, options={})
      super
      @attrs = {}
      @count_changes = {}
    end

    # Note: fields assigned directly with brackets are not tracked as changed
    # IE: post[:title] = "test"
    def call
      changed_fields = @model.changed_attributes.keys
      return if changed_fields.empty? # no changes to save
      @attrs = @model.attrs.slice(*changed_fields)
      log_debug(params)
      client.update_item(params)
    end

    # Allows updates to specific attributes and counters
    def save_changes(changes={})
      @attrs = changes[:attrs] || {}
      @count_changes = changes[:count_changes] || {}
      log_debug(params)
      client.update_item(params)
    end

    def params
      {
        expression_attribute_names: expression_attribute_names, # { "##{attribute}" => attribute },
        expression_attribute_values: expression_attribute_values, # { ':attribute' => value } or { ':by' => by }
        update_expression: update_expression, # "SET ##{attribute} = ##{attribute}" or "SET ##{attribute} = ##{attribute} + :by"
        key: @model.primary_key,
        table_name: @model.class.table_name
      }
    end
    alias to_params params

    def expression_attribute_names
      attr_names = @attrs.inject({}) do |names, (name,_)|
        names.merge!("##{name}" => name)
      end
      count_names = @count_changes.inject({}) do |names, (name,_)|
        names.merge!("##{name}" => name)
      end
      attr_names.merge(count_names)
    end

    def expression_attribute_values
      typecaster = Dynomite::Item::Typecaster.new(@model)
      attr_values = @attrs.inject({}) do |values, (name,value)|
        meta = @model.class.fields_meta[name.to_sym] # can be nil if field is not defined
        type = meta ? meta[:type] : :infer
        value = typecaster.cast_to_type(type, value, on: :write)
        values.merge!(":#{name}" => value)
      end
      count_values = @count_changes.inject({}) do |values, (name,value)|
        values.merge!(":#{name}" => value)
      end
      attr_values.merge(count_values)
    end

    def update_expression
      expressions = []
      @attrs.inject([]) do |exp, (name,_)|
        expressions << "##{name} = :#{name}"
      end
      @count_changes.inject([]) do |exp, (name,_)|
        expressions << "##{name} = ##{name} + :#{name}"
      end
      "SET " + expressions.join(', ')
    end
  end
end
