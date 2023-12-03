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
    class_attribute :fields_map
    self.fields_map = {}
    class_attribute :id_prefix_value

    include Components
    include Abstract
    abstract!

    # Must come after include Dynomite::Associations
    def self.inherited(subclass)
      subclass.id_prefix_value = subclass.name.underscore
      # Not direct descendants of Dynomite::Item are abstract
      # IE: SchemaMigration < Dynomite::Item
      subclass.abstract! if subclass.name == "ApplicationItem"
      subclass.class_attribute :fields_map
      subclass.fields_map = {}
      super # Dynomite::Associations.inherited
    end

    delegate :partition_key_field, :sort_key_field, to: :class
    attr_reader :attrs
    attr_accessor :new_record
    alias_method :new_record?, :new_record
    def initialize(attrs={}, &block)
      run_callbacks(:initialize) do
        @new_record = true
        attrs = attrs.to_hash if attrs.respond_to?(:to_hash) # IE: ActionController::Parameters
        raise ArgumentError, "attrs must be a Hash. attrs is a #{attrs.class}" unless attrs.is_a?(Hash)
        @attrs = ActiveSupport::HashWithIndifferentAccess.new(attrs)
        attrs.each do |k,v|
          send("#{k}=", v) if respond_to?("#{k}=") # so typecasting happens
        end
        @associations = {}

        if block
          yield(self)
        end
      end
    end

    # Keeps the current attrs
    def attrs=(attrs)
      @attrs.deep_merge!(attrs)
    end

    # Longer hand methods for completeness. Internally encourage shorter attrs.
    alias_method :attributes=, :attrs=
    alias_method :attributes, :attrs

    # Because using `define_attribute_methods *names` as part of `add_field` dsl.
    # Found that define_attribute_methods is required for dirty support.
    # This adds missing_attribute method that will look for a method called attribute.
    #   send(match.target, match.attr_name, *args, &block)
    #   send(:attribute, :my_column)
    # The error message when an attribute is not found is more helpful when this is defined.
    #
    # It looks confusing that we always raise an error for attribute because fields must
    # be defined to access them through dot notation. This is because users to
    # explicitly define fields and access undeclared fields with hash notation [],
    # read_attribute, or attributes.
    def attribute(name)
      raise NoMethodError, "undefined method '#{name}' for #{self.class}"
    end

    def read_attribute(field)
      @attrs[field.to_sym]
    end

    # Only updates in memory, does not save to database.
    # Same as ActiveRecord behavior.
    def write_attribute(field, value)
      @attrs[field.to_sym] = value
    end

    def update_attribute(field, value)
      write_attribute(field, value)
      update(@attrs, {validate: false})
      valid? # ActiveRecord return value behavior
    end

    def delete_attribute(field)
      @attrs.delete(field.to_sym)
      update(@attrs, {validate: false})
      valid? # ActiveRecord does not have a delete_attribute. Follow update_attribute behavior.
    end
    alias :remove_attribute :delete_attribute

    def update_attribute_presence(field, value)
      if value.present?
        update_attribute(field, value)
      else # nil or empty string or empty array
        delete_attribute(field)
      end
    end

    def [](field)
      read_attribute(field)
    end

    def []=(field, value)
      write_attribute(field, value)
    end

    # For render json: item
    def as_json(options={})
      @attrs
    end

    # Required for ActiveModel
    def persisted?
      !new_record?
    end

    def reload
      if persisted?
        id = @attrs[partition_key_field]
        item = if sort_key_field
                 find(partition_key_field => id, sort_key_field => @attrs[sort_key_field])
               else
                 find(id) # item has different object_id
               end
        @attrs = item.attrs # replace current loaded attributes
      end
      self
    end

    # p1 = Product.first
    # p2 = Product.first
    # p1 == p2 # => true
    #
    # p1 = Product.first
    # products = Product.all
    # products.include?(p1) # => true
    def ==(other)
      self.class == other.class && self.attrs == other.attrs
    end

    def to_param
      if id
        id
      else
        raise "Need to define a id field for to_param"
      end
    end
  end
end
