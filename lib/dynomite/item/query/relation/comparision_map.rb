class Dynomite::Item::Query::Relation
  module ComparisionMap
    COMPARISION_MAP = {
      'eq' => '=',
      'gt' => '>',
      'gte' => '>=',
      'lt' => '<',
      'lte' => '<=',
    }

    def comparision_for(operator)
      COMPARISION_MAP[operator] || operator
    end

    def comparision_operators
      COMPARISION_MAP.keys + COMPARISION_MAP.values
    end
  end
end
