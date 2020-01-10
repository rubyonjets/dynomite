require "active_model"
require "digest"
require "yaml"

# The model is ActiveModel compatiable even though DynamoDB is a different type of database.
#
# Examples:
#
#   post = Post.new(id: "myid", title: "my title")
#   post.save
#
# post.id now contain a generated unique partition_key id.
#
module Dynomite
  class Item
    include Components

    attr_reader :attrs
    attr_writer :new_record
    def initialize(attrs={})
      run_callbacks(:initialize) do
        @attrs = ActiveSupport::HashWithIndifferentAccess.new(attrs)
        @new_record = true
      end
    end

    # Keeps the current attrs
    def attrs=(attrs)
      @attrs.deep_merge!(attrs)
    end

    # Longer hand methods for completeness. Internally encourage use the shorter attrs method.
    alias_method :attributes=, :attrs=
    alias_method :attributes, :attrs

    def write_attribute(field, value)
      @attrs[field.to_sym] = value
    end

    def read_attribute(field)
      @attrs[field.to_sym]
    end

    def update_attribute(field, value)
      write_attribute(field, value)
      update(@attrs, {validate: false})
    end

    def partition_key
      self.class.partition_key
    end

    # For render json: item
    def as_json(options={})
      @attrs
    end

    def new_record?
      @new_record
    end

    # Required for ActiveModel
    def persisted?
      !new_record?
    end

    def reload
      if persisted?
        id = @attrs[partition_key]
        item = find(id) # item has different object_id
        @attrs = item.attrs # replace current loaded attributes
      end
      self
    end
  end
end
