class Dynomite::Item
  class Typecast
    class << self
      def cast(type, value)
        case type
        when "datetime"
          Time.parse(value)
        else # infer typecast from the stored value built into the aws-sdk-dynamodb
          # https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sdk-dynamodb/lib/aws-sdk-dynamodb/attribute_value.rb
          value # passthrough
        end
      end
    end
  end
end
