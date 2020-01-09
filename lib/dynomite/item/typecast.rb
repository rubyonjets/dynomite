class Dynomite::Item
  class Typecast
    class << self
      def load_item(type, value)
        case type
        when "datetime"
          Time.parse(value)
        else # infer typecast from the stored value built into the aws-sdk-dynamodb
          # https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sdk-dynamodb/lib/aws-sdk-dynamodb/attribute_value.rb
          value # passthrough
        end
      end

      def dump_item(type, value)
        case type
        when "datetime"
          value.respond_to?(:utc) ? value.utc.strftime('%Y-%m-%dT%TZ') : value
        else # infer typecast from the stored value built into the aws-sdk-dynamodb
          # https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sdk-dynamodb/lib/aws-sdk-dynamodb/attribute_value.rb
          value # passthrough
        end
      end

      # TODO: implement and add spec
      def dump(meta, params)
        # case params
        # when Hash
        #   params.map
        # when Array
        # else
        # end
        params
      end
    end
  end
end
