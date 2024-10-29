module Dynomite
  module Types
    TYPE_MAP = {
      string: 'S',
      number: 'N',
      binary: 'B',
      boolean: 'BOOL',
      null: 'NULL',
      map: 'M',
      list: 'L',
      string_set: 'SS',
      number_set: 'NS',
      binary_set: 'BS',
    }

    # https://v5.docs.rubyonjets.com/docs/database/dynamodb/types/
    # https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html#HowItWorks.DataTypeDescriptors
    def type_map(attribute_type)
      TYPE_MAP[attribute_type.to_s.downcase.to_sym] || attribute_type
    end
  end
end
