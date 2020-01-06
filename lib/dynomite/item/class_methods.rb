class Dynomite::Item
  module ClassMethods
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
    def scan(params={})
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
    def query(params={})
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
    def where(attributes, options={})
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

    def replace(attrs)
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
      db.put_item(
        table_name: table_name,
        item: item
      )

      # The resp does not contain the attrs. So might as well return
      # the original item with the generated partition_key value
      item
    end

    def find(id)
      params =
        case id
        when String
          { partition_key => id }
        when Hash
          id
        end

      resp = db.get_item(
        table_name: table_name,
        key: params
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
    def delete(key_object, options={})
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

      db.delete_item(params) # resp
    end

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

    def table_name(*args)
      case args.size
      when 0
        get_table_name
      when 1
        set_table_name(args[0])
      end
    end

    def get_table_name
      @table_name ||= self.name.pluralize.gsub('::','-').underscore.dasherize
      [table_namespace, @table_name].reject {|s| s.nil? || s.empty?}.join(namespace_separator)
    end

    def namespace_separator
      separator = db_config["table_namespace_separator"] || "-"
      if separator == "-"
        puts "INFO: table_namespace_separator is '-'. Ths is deprecated. Next major release will have '_' as the separator. You can override this to `table_namespace_separator: -` config/dynamodb.yml but is encouraged to rename your tables.".color(:yellow)
      end
      separator
    end

    def set_table_name(value)
      @table_name = value
    end

    def table
      Aws::DynamoDB::Table.new(name: table_name, client: db)
    end

    def count
      table.item_count
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
