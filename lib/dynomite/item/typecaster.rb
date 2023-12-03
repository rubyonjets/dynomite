require "time"

# aws-sdk-dynamodb handles typecast heavy-lifting. Adds typecasting support for DateTime objects.
class Dynomite::Item
  class Typecaster
    def initialize(model)
      @model = model
    end

    def dump(data, depth=0)
      case data
      when Array
        data.map! { |v| dump(v, depth+1) }
      when Hash
        data.each_with_object({}) do |(k,v), dumped|
          if depth == 0
            v = cast_to_attribute_type(k, v) # cast to attribute type if defined
          end
          dumped[k] = dump(v, depth+1)
          dumped
        end
      else
        data # pass through
      end
    end

    # IE: field :price, type: :integer
    # For most cases, we rely on aws-sdk-dynamodb to do the typecasting by inference.
    #
    # The method also helps keep track of where we cast_to_type
    # It's only a few spots this provides an easy to search for it.
    # See: https://rubyonjets.com/docs/database/dynamodb/model/typecasting/
    FALSEY = [false, 'false', 'FALSE', 0, '0', 'f', 'F', 'off', 'OFF']
    def cast_to_type(type, value, on: :read)
      case type
      when :integer
        value.to_i
      when :boolean
        !FALSEY.include?(value)
      when :time
        cast_to_time(value, on: on)
      when :string
        value.to_s # force to string
      else # :infer
        value # passthrough and let aws-sdk-dynamodb handle it
      end
    end

    # datetime to string
    def cast_to_time(value, on: :read)
      if on == :read
        if value.is_a?(String)
          Time.parse(value) # 2023-08-26T14:35:37Z
        elsif value.respond_to?(:to_datetime) # time-like object already Time or DateTime
          value
        end
      else # write or raw (for querying)
        if value.respond_to?(:to_datetime) && !value.is_a?(String)
          value.utc.strftime('%Y-%m-%dT%TZ') # Timestamp format iso8601 from AWS docs: http://amzn.to/2z98Bdc
        else
          value # passthrough string
        end
      end
    end

    # string to float if attribute_type is N
    # number to string if attribute_type is S
    def cast_to_attribute_type(attribute_name, attribute_value)
      definition = @model.attribute_definitions.find { |d| d[:attribute_name] == attribute_name.to_s }
      if definition
        case definition[:attribute_type]
        when "N"  # Number
          attribute_value.to_f
        when "S"  # String
          attribute_value.to_s
        when "BOOL" # Boolean
          attribute_value == true
        else
          attribute_value # passthrough
        end
      else
        attribute_value # passthrough
      end
    end

    def load(data)
      case data
      when Array
        data.map! { |v| load(v) }
      when Hash
        data.each_with_object({}) do |(k,v), loaded|
          loaded[k] = load(v)
          loaded
        end
      else
        load_item(data)
      end
    end

    REGEXP = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/
    def load_item(obj)
      return obj unless obj.is_a?(String)
      obj.match(REGEXP) ? Time.parse(obj) : obj
    end
  end
end
