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
    include Log
    include DbConfig
    include Errors

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

    # Adds very little wrapper logic to scan.
    #
    # * Automatically add table_name to options for convenience.
    # * Decorates return value.  Returns Array of [MyModel.new] instead of the
    #   dynamodb client response.
    #
    # Other than that, usage is same was using the dynamodb client scan method
    # directly.  Example:
    #
    #   MyModel.scan(
    #     expression_attribute_names: {"#updated_at"=>"updated_at"},
    #     filter_expression: "#updated_at between :start_time and :end_time",
    #     expression_attribute_values: {
    #       ":start_time" => "2010-01-01T00:00:00",
    #       ":end_time" => "2020-01-01T00:00:00"
    #     }
    #   )
    #
    # AWS Docs examples: http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.Ruby.04.html
    def self.scan(params={})
      log("It's recommended to not use scan for production. It can be slow and expensive. You can a LSI or GSI and query the index instead.")
      log("Scanning table: #{table_name}")
      params = { table_name: table_name }.merge(params)
      resp = db.scan(params)
      resp.items.map {|i| self.new(i) }
    end

    # Adds very little wrapper logic to query.
    #
    # * Automatically add table_name to options for convenience.
    # * Decorates return value.  Returns Array of [MyModel.new] instead of the
    #   dynamodb client response.
    #
    # Other than that, usage is same was using the dynamodb client query method
    # directly.  Example:
    #
    #   MyModel.query(
    #     index_name: 'category-index',
    #     expression_attribute_names: { "#category_name" => "category" },
    #     expression_attribute_values: { ":category_value" => "Entertainment" },
    #     key_condition_expression: "#category_name = :category_value",
    #   )
    #
    # AWS Docs examples: http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.Ruby.04.html
    def self.query(params={})
      params = { table_name: table_name }.merge(params)
      resp = db.query(params)
      resp.items.map {|i| self.new(i) }
    end

    # Translates simple query searches:
    #
    #   Post.where({category: "Drama"}, index_name: "category-index")
    #
    # translates to
    #
    #   resp = db.query(
    #     table_name: "demo-dev-post",
    #     index_name: 'category-index',
    #     expression_attribute_names: { "#category_name" => "category" },
    #     expression_attribute_values: { ":category_value" => category },
    #     key_condition_expression: "#category_name = :category_value",
    #   )
    #
    # TODO: Implement nicer where syntax with index_name as a chained method.
    #
    #   Post.where({category: "Drama"}, {index_name: "category-index"})
    #     VS
    #   Post.where(category: "Drama").index_name("category-index")
    def self.where(attributes, options={})
      raise "attributes.size == 1 only supported for now" if attributes.size != 1

      attr_name = attributes.keys.first
      attr_value = attributes[attr_name]

      # params = {
      #   expression_attribute_names: { "#category_name" => "category" },
      #   expression_attribute_values: { ":category_value" => "Entertainment" },
      #   key_condition_expression: "#category_name = :category_value",
      # }
      name_key, value_key = "##{attr_name}_name", ":#{attr_name}_value"
      params = {
        expression_attribute_names: { name_key => attr_name },
        expression_attribute_values: { value_key => attr_value },
        key_condition_expression: "#{name_key} = #{value_key}",
      }
      # Allow direct access to override params passed to dynamodb query options.
      # This is is how index_name is passed:
      params = params.merge(options)

      query(params)
    end

    def self.replace(attrs)
      # Automatically adds some attributes:
      #   partition key unique id
      #   created_at and updated_at timestamps. Timestamp format from AWS docs: http://amzn.to/2z98Bdc
      defaults = {
        partition_key => Digest::SHA1.hexdigest([Time.now, rand].join)
      }
      item = defaults.merge(attrs)
      item["created_at"] ||= Time.now.utc.strftime('%Y-%m-%dT%TZ')
      item["updated_at"] = Time.now.utc.strftime('%Y-%m-%dT%TZ')

      # put_item full replaces the item
      resp = db.put_item(
        table_name: table_name,
        item: item
      )

      # The resp does not contain the attrs. So might as well return
      # the original item with the generated partition_key value
      item
    end

    def self.find(id)
      resp = db.get_item(
        table_name: table_name,
        key: {partition_key => id}
      )
      attributes = resp.item # unwraps the item's attributes
      self.new(attributes) if attributes
    end

    # Two ways to use the delete method:
    #
    # 1. Specify the key as a String. In this case the key will is the partition_key
    # set on the model.
    #   MyModel.delete("728e7b5df40b93c3ea6407da8ac3e520e00d7351")
    #
    # 2. Specify the key as a Hash, you can arbitrarily specific the key structure this way
    # MyModel.delete("728e7b5df40b93c3ea6407da8ac3e520e00d7351")
    #
    # options is provided in case you want to specific condition_expression or
    # expression_attribute_values.
    def self.delete(key_object, options={})
      if key_object.is_a?(String)
        key = {
          partition_key => key_object
        }
      else # it should be a Hash
        key = key_object
      end

      params = {
        table_name: table_name,
        key: key
      }
      # In case you want to specify condition_expression or expression_attribute_values
      params = params.merge(options)

      resp = db.delete_item(params)
    end

    # When called with an argument we'll set the internal @partition_key value
    # When called without an argument just retun it.
    # class Comment < Dynomite::Item
    #   partition_key "post_id"
    # end
    def self.partition_key(*args)
      case args.size
      when 0
        @partition_key || "id" # defaults to id
      when 1
        @partition_key = args[0].to_s
      end
    end

    def self.table_name(*args)
      case args.size
      when 0
        get_table_name
      when 1
        set_table_name(args[0])
      end
    end

    def self.get_table_name
      @table_name ||= self.name.pluralize.underscore
      [table_namespace, @table_name].reject {|s| s.nil? || s.empty?}.join('-')
    end

    def self.set_table_name(value)
      @table_name = value
    end

    def self.table
      Aws::DynamoDB::Table.new(name: table_name, client: db)
    end

    def self.count
      table.item_count
    end

    # Defines column. Defined column can be accessed by getter and setter methods of the same
    # name (e.g. [model.my_column]). Attributes with undefined columns can be accessed by
    # [model.attrs] method.
    def self.column(*names)
      names.each(&method(:add_column))
    end

    # @see Item.column
    def self.add_column(name)
      if Dynomite::RESERVED_WORDS.include?(name)
        raise ReservedWordError, "'#{name}' is a reserved word"
      end

      define_method(name) do
        @attrs[name.to_s]
      end

      define_method("#{name}=") do |value|
        @attrs[name.to_s] = value
      end
    end
  end
end
