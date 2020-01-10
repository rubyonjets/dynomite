module Dynomite::Item::Query::Write
  class Save < Base
    def call
      params = {
        table_name: @model.class.table_name,
        item: @model.attrs
      }
      params = Dynomite::Item::Typecaster.dump(params)
      Dynomite.logger.debug("put_item params: #{params}")
      # put_item replaces the item fully. The resp does not contain the attrs.
      db.put_item(params)

      @model.new_record = false
      true
    end
  end
end
