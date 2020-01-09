class Dynomite::Item
  module Query
    extend ActiveSupport::Concern

    # Not using method_missing to allow usage of dot notation and assign
    # @attrs because it might hide actual missing methods errors.
    # DynamoDB attrs can go many levels deep so it makes less make sense to
    # use to dot notation.

    def save(attrs={})
      @attrs = @attrs.deep_merge(attrs)

      # valid? method comes from ActiveModel::Validations
      if respond_to? :valid?
        return false unless valid?
      end

      attrs = self.class.save(@attrs)

      @attrs = attrs # refresh attrs because it now has the id
      self
    end
    alias_method :replace, :save

    # Similar to replace, but raises an error on failed validation.
    # Works that way only if ActiveModel::Validations are included
    def save!(attrs={})
      raise ValidationError, "Validation failed: #{errors.full_messages.join(', ')}" unless replace(attrs)
    end
    alias_method :replace!, :save!

    def find(id)
      self.class.find(id)
    end

    def delete
      self.class.delete(@attrs[:id]) if @attrs[:id]
    end

    class_methods do
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
      #     expression_attribute_values: {
      #       ":start_time" => "2010-01-01T00:00:00",
      #       ":end_time" => "2020-01-01T00:00:00"
      #     },
      #     filter_expression: "#updated_at between :start_time and :end_time",
      #   )
      #
      # AWS Docs examples: http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.Ruby.04.html
      def scan(params={})
        Dynomite.logger.info("It's recommended to not use scan for production. It can be slow and expensive. You can a LSI or GSI and query the index instead.")
        Dynomite.logger.info("Scanning table: #{table_name}")
        params = { table_name: table_name }.merge(params)
        resp = db.scan(params)
        Dynomite.logger.info("REQUEST: #{params}")
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
        resp.items.map { |i| self.new(i) }
      end

      def where(args)
        Builder.new(self).where(args)
      end

      %w[all first last].each do |meth|
        define_method(meth) do
          where({}).send(meth)
        end
      end

      def find_by(attrs)
        where(attrs).first
      end

      def save(attrs)
        # Automatically adds some attributes:
        #   partition key unique id
        #   created_at and updated_at timestamps. Timestamp format from AWS docs: http://amzn.to/2z98Bdc
        defaults = {
          partition_key => Digest::SHA1.hexdigest([Time.now, rand].join)
        }
        item = defaults.merge(attrs)
        # TODO: use Time.now and Typecast.dump values that match the a date pattern
        item["created_at"] ||= Time.now.utc.strftime('%Y-%m-%dT%TZ')
        item["updated_at"] = Time.now.utc.strftime('%Y-%m-%dT%TZ')

        params = {
          table_name: table_name,
          item: item
        }
        params = Typecast.dump(fields, params)
        Dynomite.logger.debug("put_item params: #{params}")
        # put_item full replaces the item
        db.put_item(params)

        # The resp does not contain the attrs. So might as well return
        # the original item with the generated partition_key value
        item
      end
      alias_method :replace, :save

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
        attrs = resp.item # unwraps the item's attrs
        self.new(attrs) if attrs
      end

      # Two ways to use the delete method:
      #
      # 1. Specify the key as a String. In this case the key will is the partition_key set on the model.
      #
      #   MyModel.delete("728e7b5df40b93c3ea6407da8ac3e520e00d7351")
      #
      # 2. Specify the key as a Hash, you can arbitrarily specific the key structure this way
      #
      #   MyModel.delete(id: "728e7b5df40b93c3ea6407da8ac3e520e00d7351")
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

      def count
        table.item_count # can be stale
      end

      def table
        Aws::DynamoDB::Table.new(name: table_name, client: db)
      end

      def create(attrs={})
        item = new(attrs)
        item.save
        item
      end
    end
  end
end
