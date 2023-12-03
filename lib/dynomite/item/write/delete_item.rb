module Dynomite::Item::Write
  class DeleteItem < Base
    def call
      key = @model.attrs.slice(@model.class.partition_key_field, @model.class.sort_key_field)
      params = {
        table_name: @model.class.table_name,
        key: key
      }
      # In case you want to specify condition_expression or expression_attribute_values
      params = params.merge(@options)
      client.delete_item(params) # resp
    end
  end
end
