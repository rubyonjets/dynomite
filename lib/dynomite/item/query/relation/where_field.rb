class Dynomite::Item::Query::Relation
  class WhereField
    attr_reader :full_field, :value, :index
    def initialize(full_field, value, index)
      @full_field, @value, @index = full_field.to_s, value, index
    end

    def field
      @full_field.split('.').first
    end

    def operator
      if raw_operator
        not? ? raw_operator[4..-1] : raw_operator
      end
    end

    def not?
      raw_operator.match(/^not_/) if raw_operator
    end

    def raw_operator
      _, operator = @full_field.split('.')
      operator.downcase if operator
    end

    # Example: price_1, price_2
    def reference
      "#{field}_#{@index}"
    end
  end
end
