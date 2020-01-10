require "time"

# aws-sdk-dynamodb handles typecast heavy-lifting. Adds typecasting support for DateTime objects.
class Dynomite::Item
  class Typecaster
    def dump(data)
      case data
      when Array
        data.map! { |v| dump(v) }
      when Hash
        data.each_with_object({}) do |(k,v), dumped|
          dumped[k] = dump(v)
          dumped
        end
      else
        dump_item(data)
      end
    end

    def dump_item(obj)
      # !obj.is_a?(String) because activesupport/core_ext/string/conversions adds .to_date
      if obj.respond_to?(:to_datetime) && !obj.is_a?(String)
        obj.utc.strftime('%Y-%m-%dT%TZ') # Timestamp format iso8601 from AWS docs: http://amzn.to/2z98Bdc
      else
        obj
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

    class << self
      def dump(data)
        new.dump(data)
      end

      def load(data)
        new.load(data)
      end
    end
  end
end
