require "dynomite/reserved_words"

class Dynomite::Item
  module Dsl
    # When called with an argument we'll set the internal @partition_key value
    # When called without an argument just retun it.
    # class Comment < Dynomite::Item
    #   partition_key "post_id"
    # end
    def partition_key(*args)
      case args.size
      when 0
        @partition_key || "id" # defaults to id
      when 1
        @partition_key = args[0].to_s
      end
    end

    # Defines column. Defined column can be accessed by getter and setter methods of the same
    # name (e.g. [model.my_column]). Attributes with undefined columns can be accessed by
    # [model.attrs] method.
    def field(*names)
      names.each(&method(:add_field))
    end
    alias_method :column, :field

    # @see Item.column
    def add_field(name)
      name = name.to_s
      name, type = name.split(':')
      type ||= :infer
      self.fields.merge!(name => {"type" => type}) # store field metadata

      if Dynomite::RESERVED_WORDS.include?(name)
        raise ReservedWordError, "'#{name}' is a reserved word"
      end

      define_method(name) do
        @attrs ||= {}
        value = @attrs[name]
        meta = self.class.fields[name]
        Typecast.load_item(meta["type"], value)
      end

      define_method("#{name}=") do |value|
        @attrs ||= {}
        @attrs[name] = value
      end
    end
  end
end
