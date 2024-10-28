module Dynomite::Item::Read
  module FindWithEvent
    extend ActiveSupport::Concern

    class_methods do
      def find_all_with_stream_event(event, options={})
        # For event payload structure see
        # https://v5.docs.rubyonjets.com/docs/events/dynamodb/#event-payload
        # Keys structure:
        # {
        #   "Records": [
        #     "dynamodb": {
        #       "Keys": {
        #         "id": {
        #           "S": "post-1"
        #         }
        #       },
        event = JSON.load(event) if event.is_a?(String)
        event = event.deep_symbolize_keys
        # raw_keys: { "id": { "S": "post-1" } }
        raw_keys = event[:Records].map do |record|
          record[:dynamodb][:Keys]
        end
        # keys: { id: "post-1" }
        keys = get_key_schema_from_raw_keys(raw_keys)
        items = find(keys, options) # find can return single item or Array of items
        Array(items) # ensure Array is returned
      end

      def get_key_schema_from_raw_keys(raw_keys)
        # raw_keys: { "id": { "S": "post-1" } }
        # keys: { id: "post-1" }
        # Note: raw_keys can have duplicates.
        # IE: [{ "id": { "S": "post-1" }, "id": { "S": "post-1" } }]
        keys = raw_keys.uniq.map do |hash|
          hash.transform_values { |value| value.values.first }
        end
        get_key_schema_from_one_arg(keys)
      end
    end
  end
end
