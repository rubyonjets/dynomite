class Dynomite::Item::Query::Relation
  class ComparisionExpression
    def initialize(where_group, comparisions)
      @where_group, @comparisions = where_group, comparisions
    end

    def or?
      @where_group.or?
    end

    def build
      # join @comparisions with AND if there are more than one
      expression = []
      expression << 'NOT' if @where_group.not?
      expression << '(' if @comparisions.size > 1
      expression << @comparisions.join(' AND ') # always AND within a group
      expression << ')' if @comparisions.size > 1
      expression.join(' ')
    end
  end
end
