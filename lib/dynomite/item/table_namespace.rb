class Dynomite::Item
  module TableNamespace
    extend ActiveSupport::Concern

    def table_name
      self.class.table_name
    end

    class_methods do
      def table_name(*args)
        case args.size
        when 0
          get_table_name
        when 1
          set_table_name(args[0])
        end
      end

      def set_table_name(value)
        @table_name = value
      end

      def get_table_name
        @table_name ||= self.name.pluralize.gsub('::','-').underscore.dasherize
        [table_namespace, @table_name].reject {|s| s.nil? || s.empty?}.join(namespace_separator)
      end

      def table_namespace(*args)
        case args.size
        when 0
          get_table_namespace
        when 1
          set_table_namespace(args[0])
        end
      end

      def get_table_namespace
        return @table_namespace if defined?(@table_namespace)
        @table_namespace = Dynomite.config.table_namespace
      end

      def set_table_namespace(value)
        @table_namespace = value
      end

      def namespace_separator
        legacy = File.exist?("#{Dynomite.root}/config/dynamodb.yml")
        default = legacy ? '-' : '_'
        separator = Dynomite.config.namespace_separator || default
        # if legacy && separator == '-'
        #   Dynomite.logger.info "INFO: namespace_separator is '-' is deprecated. Next major release will have '_' as the separator. You can override this to `table_namespace_separator: -` config/dynamodb.yml but is encouraged to rename your tables.".color(:yellow)
        # end
        separator
      end
    end
  end
end
