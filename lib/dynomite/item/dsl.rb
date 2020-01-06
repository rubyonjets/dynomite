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
    def column(*names)
      names.each(&method(:add_column))
    end

    # @see Item.column
    def add_column(name)
      if Dynomite::RESERVED_WORDS.include?(name)
        raise ReservedWordError, "'#{name}' is a reserved word"
      end

      define_method(name) do
        @attrs ||= {}
        @attrs[name.to_s]
      end

      define_method("#{name}=") do |value|
        @attrs ||= {}
        @attrs[name.to_s] = value
      end
    end
  end
end
