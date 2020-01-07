require "active_model"
require "digest"
require "yaml"

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
    extend Dsl
    extend Indexes
    extend Memoist
    include ActiveModel::Model
    include ActiveModel::Validations
    include Client
    include Errors
    include Query
    include TableNamespace
    include WaiterMethods

    attr_writer :new_record
    def initialize(attrs={})
      @attrs = attrs
      @new_record = true
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

    def new_record?
      @new_record
    end
  end
end
