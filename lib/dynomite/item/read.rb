class Dynomite::Item
  module Read
    extend ActiveSupport::Concern
    include Find
    include FindWithEvent
    include Query

    class_methods do
      # Override Enumerable#first to limit to 1 item as optimization
      def first
        all.limit(1).first
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
      #     expression_attribute_values: {
      #       ":start_time" => "2010-01-01T00:00:00",
      #       ":end_time" => "2020-01-01T00:00:00"
      #     },
      #     filter_expression: "#updated_at between :start_time and :end_time",
      #   )
      #
      # AWS Docs examples: http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.Ruby.04.html
      def scan(params={})
        params = { table_name: table_name }.merge(params)
        resp = client.scan(params)
        logger.info("REQUEST: #{params}")
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
        resp = client.query(params)
        resp.items.map { |i| self.new(i) }
      end

      def count
        if Dynomite.config.default_count_method.to_sym == :item_count
          item_count
        else
          scan_count
        end
      end
      alias_method :size, :count

      def scan_count
        warn_scan <<~EOL
          WARN: Using scan to count. Though it is more accurate.
          It can be slow and expensive. You can use item_count instead.
          Note: item_count may be stale for about 6 hours.
          You can set the Dynomite.config.default_count_method = :item_count to make it the default.
        EOL
        all.count
      end

      # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Table.html#item_count-instance_method
      # DynamoDB updates this value approximately every six hours.
      def item_count
        table = Aws::DynamoDB::Table.new(name: table_name, client: client)
        table.item_count # fast but can be stale
      end
    end
  end
end