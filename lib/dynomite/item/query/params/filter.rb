class Dynomite::Item::Query::Params
  class Filter < Base
    def initialize(relation, index)
      @relation, @index = relation, index
      @expressions = []
    end

    def build
      build_where
      build_functions
    end
    memoize :build

    def expression
      build
      join_expressions
    end

    def build_where
      with_where_groups do |where_group|
        expression = where_group.build_compare_expression_if do |field|
          @index.nil? || !@index.fields.include?(field)
        end
        @expressions << expression if expression
      end
    end

    # https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.OperatorsAndFunctions.html
    def build_functions
      # Essentially
      #    @expressions += Function::AttributeExists.new(@query).filter_expression
      #    @expressions += Function::AttributeType.new(@query).filter_expression
      #    @expressions += Function::BeginsWith.new(@query).filter_expression
      function_names.each do |function_name|
        function = Function.const_get(function_name.camelize).new(@relation.query)
        filter_expression = function.filter_expression
        @expressions += filter_expression
      end
    end
  end
end
