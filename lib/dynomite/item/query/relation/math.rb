class Dynomite::Item::Query::Relation
  module Math
    def average(field)
      map(&field).sum.to_f / count
    end

    def min(field)
      map(&field).min
    end

    def max(field)
      map(&field).max
    end

    def sum(field)
      map(&field).sum
    end
  end
end
