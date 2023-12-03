class Dynomite::Item::Query::Params
  class Base
    extend Memoist
    include Dynomite::Types
    include Helpers

    # To add function example:
    # 1. params/base.rb function_names
    # 2. query/chain.rb: add method
    # 3. params/function/begins_with.rb: filter_expression, attribute_names, attribute_values
    def function_names
      %w[attribute_exists attribute_type begins_with contains size_fn]
    end

    def join_expressions
      joined = ''
      @expressions.each do |expression|
        string = expression_string(expression)
        if joined.empty? # first pass
          joined << string
        else
          if !expression.is_a?(String) && expression.or?
            joined << " OR #{string}"
          else
            joined << " AND #{string}"
          end
        end
      end
      joined
    end

    def expression_string(expression)
      if expression.is_a?(String)
        # Function filter expression is simple String
        expression
      else
        # Else expression is CompressionExpression object with extra info like .or?
        expression.build  # build the string
      end
    end
  end
end
