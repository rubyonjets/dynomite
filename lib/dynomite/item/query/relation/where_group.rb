class Dynomite::Item::Query::Relation
  class WhereGroup
    delegate :keys, :size, to: :hash
    include ComparisionMap

    attr_accessor :hash, :meta
    def initialize(relation, hash={}, meta={})
      @relation = relation
      @hash = hash
      @meta = meta
    end

    def to_s
      "#<#{self.class.name} @hash=#{@hash} @meta=#{@meta}>"
    end

    def each
      @hash.each do |full_field, value|
        where_field = WhereField.new(full_field, value, @relation.index)
        yield where_field
        @relation.index += 1
      end
    end

    def fields
      @hash.map do |full_field, value|
        full_field.to_s.split('.').first
      end
    end

    def not?
      @meta[:not]
    end

    def or?
      @meta[:or]
    end

    # Method helps remove duplication and DRY up building of compare expression.
    # It a bit confusing but unsure how to make it clearer.
    def build_compare_expression_if
      comparisions = []
      each do |where_field|
        field = where_field.field
        next unless yield(field) # only build if condition is true
        comparisions << build_compare(where_field)
      end
      unless comparisions.empty?
        ComparisionExpression.new(self, comparisions) # to pass in where_group for or? and not?
      end
    end

    def build_compare(where_field)
      reference = where_field.reference
      operator = where_field.operator
      expression = case operator
      when 'in'
        # ProductStatus in (:avail, :back, :disc)
        array = Array(where_field.value)
        list = array.map.with_index { |v, i| ":#{reference}_#{i}" }.join(', ') # values
        "##{reference} in (#{list})"
      when 'between'
        # sortKeyName between :sortkeyval1 AND :sortkeyval2
        "##{reference} between :#{reference}_0 AND :#{reference}_1"
      when 'begins_with'
        # begins_with ( sortKeyName, :sortkeyval )
        "begins_with(##{reference}, :#{reference})"
      when *comparision_operators # eq, gt, gte, lt, lte, =, >, >=, <, <=
        comparision = comparision_for(operator)
        "##{reference} #{comparision} :#{reference}"
      else
        "##{reference} = :#{reference}"
      end
      expression = "NOT (#{expression})" if where_field.not?
      expression
    end
  end
end
