module Dynomite::Item::Query
  module Partiql
    extend ActiveSupport::Concern
    class_methods do
      # Example:
      #
      #   Product.execute_pql('SELECT * FROM "demo-dev_products" WHERE name = ?', ['Laptop'])
      #
      # Note WHERE is required
      def execute_pql(statement, parameters = {}, options = {})
        Executer.new(self).call(statement, parameters, options)
      end

      # Example:
      #
      #   Product.execute_pql('SELECT * FROM "demo-dev_products" WHERE name = ?', ['Laptop'])
      #   Product.find_by_pql('name = ?', ['Laptop'])
      #
      # Returns [Item, Item, ...] (lazy)
      def find_by_pql(where, parameters = {}, options = {})
        select_all(where, parameters, options.merge(raw: false))
      end

      # Example:
      #
      #   Product.execute_pql('SELECT * FROM "demo-dev_products" WHERE name = ?', ['Laptop'])
      #   Product.select_all('name = ?', ['Laptop'])
      #
      # Returns [Hash, Hash, ...] (lazy)
      def select_all(where, parameters = {}, options = {})
        options[:raw] = true unless options.key?(:raw)
        statement = %Q|SELECT * FROM "#{table_name}" WHERE #{where}|
        execute_pql(statement, parameters, options)
      end

      # Example:
      #
      #   Post.execute_pql('UPDATE "demo-dev_posts" SET title = ? WHERE id = ?', ['post 1b', 'post-gRssngpbm5OfDIwr'])
      #   Post.update_pql('SET title = ? WHERE id = ?', ['post 1c', 'post-gRssngpbm5OfDIwr'])
      #
      def update_pql(set_where, parameters, options = {})
        statement = %Q|UPDATE "#{table_name}" #{set_where}|
        execute_pql(statement, parameters, options).to_a # to_a to force the lazy Enumerator to execute
      end

      # Example:
      #
      #   Post.execute_pql('DELETE FROM "demo-dev_posts" WHERE id = ?', ['post-2QXlmfHCKcPDsnJC'])
      #   Post.delete_pql('id = ?', ['post-2QXlmfHCKcPDsnJC'])
      #
      def delete_pql(where, parameters = {}, options = {})
        statement = %Q|DELETE FROM "#{table_name}" WHERE #{where}|
        execute_pql(statement, parameters, options).to_a # to_a to force the lazy Enumerator to execute
      end

      # Example:
      #
      #   Post.execute_pql(%Q|INSERT INTO "demo-dev_posts" VALUE {'id': ?, 'title': ?}|, ['post-1', 'post 1'])
      #   Post.insert_pql("{'id': ?, 'title': ?}", ['post-3', 'post 3'])
      #
      def insert_pql(values, parameters = {}, options = {})
        statement = %Q|INSERT INTO "#{table_name}" VALUE #{values}|
        execute_pql(statement, parameters, options).to_a # to_a to force the lazy Enumerator to execute
      end
    end
  end
end
