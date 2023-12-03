class Dynomite::Item::Query::Params
  class ExpressionAttribute < Base
    def initialize(relation)
      @relation = relation
      @names, @values = {}, {}
    end

    def names
      build
      @names
    end

    def values
      build
      @values
    end

    def build
      build_where
      build_functions
      build_project_expression
    end
    memoize :build

    def build_where
      with_where_groups do |where_group|
        where_group.each do |where_field|
          field = where_field.field
          reference = where_field.reference
          value = where_field.value
          @names["##{reference}"] = field

          model_class = @relation.source
          meta = model_class.fields_meta[field.to_sym] # can be nil if field is not defined
          type = meta ? meta[:type] : :infer

          if where_field.operator == "in" || value.is_a?(Array)
            array = Array(value)
            array.each_with_index do |v, i|
              @values[":#{reference}_#{i}"] = cast_to_type(type, v, on: :query)
            end
          else
            @values[":#{reference}"] = cast_to_type(type, value, on: :query)
          end
        end
      end
    end

    # https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.OperatorsAndFunctions.html
    def build_functions
      # Essentially
      #    @names.merge!(Function::AttributeExists.new(@query).attribute_names)
      #    @names.merge!(Function::AttributeType.new(@query).attribute_names)
      #    @names.merge!(Function::BeginsWith.new(@query).attribute_names)
      function_names.each do |function_name|
        function = Function.const_get(function_name.camelize).new(@relation.query)
        @names.merge!(function.attribute_names)
        @values.merge!(function.attribute_values)
      end
    end

    def build_project_expression
      return if @relation.query[:projection_expression].nil?
      projection_expression = normalize_project_expression(@relation.query[:projection_expression])
      projection_expression.each do |field|
        field = field.to_s
        @names["##{field}"] = field
      end
    end

  private

    delegate :cast_to_type, to: :typecaster
    def typecaster
      Dynomite::Item::Typecaster.new(@relation.source)
    end
    memoize :typecaster
  end
end
