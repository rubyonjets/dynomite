module Dynomite::Item::Query::Write
  class Destroy < Base
    def call
      key = @model.attrs.slice(@model.class.partition_key)
      params = {
        table_name: @model.class.table_name,
        key: key
      }
      # In case you want to specify condition_expression or expression_attribute_values
      params = params.merge(@options)
      db.delete_item(params) # resp
    end
  end
end
