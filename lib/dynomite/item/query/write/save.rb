module Dynomite::Item::Query::Write
  class Save < Base
    def call
      @model.attrs # ActiveSupport::HashWithIndifferentAccess no need to symbolize keys
      # Automatically adds some attributes:
      #   partition key unique id
      #   created_at and updated_at timestamps. Timestamp format from AWS docs: http://amzn.to/2z98Bdc
      defaults = {
        @model.class.partition_key => Digest::SHA1.hexdigest([Time.now, rand].join)
      }
      attrs = defaults.merge!(@model.attrs)
      @model.attrs(attrs)
      @model.attrs[:created_at] ||= Time.now
      @model.attrs[:updated_at] = Time.now

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
