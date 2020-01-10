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

    attr_writer :new_record
    def initialize(attrs={})
      @attrs = ActiveSupport::HashWithIndifferentAccess.new(attrs)
      @new_record = true
    end

    # Defining our own reader so we can do a deep merge if user passes in attrs
    def attrs(*args)
      case args.size
      when 0
        @attrs
      when 1
        attrs = args[0] # Hash
        if attrs.empty?
          @attrs = ActiveSupport::HashWithIndifferentAccess.new(attrs)
        else
          @attrs.deep_merge!(attrs)
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
    def attributes=(attrs)
      @attrs = ActiveSupport::HashWithIndifferentAccess.new(attrs)
    end

    def attributes
      ActiveSupport::HashWithIndifferentAccess.new(@attrs)
    end

    def new_record?
      @new_record
    end

    # Required for ActiveModel
    def persisted?
      !new_record?
    end
  end
end
