# Two ways to use the destroy method:
#
# 1. Specify the key as a String. In this case the key will is the partition_key set on the model.
#
#   MyModel.destroy("728e7b5df40b93c3ea6407da8ac3e520e00d7351")
#
# 2. Specify the key as a Hash, you can arbitrarily specific the key structure this way
#
#   MyModel.destroy(id: "728e7b5df40b93c3ea6407da8ac3e520e00d7351")
#
# options is provided in case you want to specific condition_expression or
# expression_attribute_values.
module Dynomite::Item::Query::Write
  class Destroy < Base
    def call
      obj = @model.attrs[:id]
      key = if obj.is_a?(String)
              { partition_key => obj }
            else # it should be a Hash
              obj
            end

      params = {
        table_name: table_name,
        key: key
      }
      # In case you want to specify condition_expression or expression_attribute_values
      params = params.merge(@options)
      db.delete_item(params) # resp
    end
  end
end
