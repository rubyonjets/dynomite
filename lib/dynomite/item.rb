require "active_model"
require "active_support/core_ext/hash"
require "aws-sdk-dynamodb"
require "digest"
require "yaml"

require "dynomite/reserved_words"

# The modeling is ActiveRecord-ish but not exactly because DynamoDB is a
# different type of database.
#
# Examples:
#
#   post = MyModel.new
#   post = post.replace(title: "test title")
#
# post.attrs[:id] now contain a generaetd unique partition_key id.
# Usually the partition_key is 'id'. You can set your own unique id also:
#
#   post = MyModel.new(id: "myid", title: "my title")
#   post.replace
#
# Note that the replace method replaces the entire item, so you
# need to merge the attributes if you want to keep the other attributes.
#
#   post = MyModel.find("myid")
#   post.attrs = post.attrs.deep_merge("desc": "my desc") # keeps title field
#   post.replace
#
# The convenience `attrs` method performs a deep_merge:
#
#   post = MyModel.find("myid")
#   post.attrs("desc": "my desc") # <= does a deep_merge
#   post.replace
#
# Note, a race condition edge case can exist when several concurrent replace
# calls are happening.  This is why the interface is called replace to
# emphasis that possibility.
# TODO: implement post.update with db.update_item in a Ruby-ish way.
#
module Dynomite
  class Item
    include ActiveModel::Model
    include DbConfig
    include Errors
    include Log
    extend ClassMethods

    def initialize(attrs={})
      @attrs = attrs
    end

    # Defining our own reader so we can do a deep merge if user passes in attrs
    def attrs(*args)
      case args.size
      when 0
        ActiveSupport::HashWithIndifferentAccess.new(@attrs)
      when 1
        attributes = args[0] # Hash
        if attributes.empty?
          ActiveSupport::HashWithIndifferentAccess.new
        else
          @attrs = attrs.deep_merge!(attributes)
        end
      end
    end

    # Not using method_missing to allow usage of dot notation and assign
    # @attrs because it might hide actual missing methods errors.
    # DynamoDB attrs can go many levels deep so it makes less make sense to
    # use to dot notation.

    # The method is named replace to clearly indicate that the item is
    # fully replaced.
    def replace(hash={})
      @attrs = @attrs.deep_merge(hash)

      # valid? method comes from ActiveModel::Validations
      if respond_to? :valid?
        return false unless valid?
      end

      attrs = self.class.replace(@attrs)

      @attrs = attrs # refresh attrs because it now has the id
      self
    end

    # Similar to replace, but raises an error on failed validation.
    # Works that way only if ActiveModel::Validations are included
    def replace!(hash={})
      raise ValidationError, "Validation failed: #{errors.full_messages.join(', ')}" unless replace(hash)
    end

    def find(id)
      self.class.find(id)
    end

    def delete
      self.class.delete(@attrs[:id]) if @attrs[:id]
    end

    def table_name
      self.class.table_name
    end

    def partition_key
      self.class.partition_key
    end

    # For render json: item
    def as_json(options={})
      @attrs
    end

    # Longer hand methods for completeness.
    # Internallly encourage the shorter attrs method.
    def attributes=(attributes)
      @attributes = attributes
    end

    def attributes
      @attributes
    end

  end
end
