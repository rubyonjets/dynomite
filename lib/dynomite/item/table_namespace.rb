class Dynomite::Item
  module TableNamespace
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
      @table_name ||= self.name.pluralize.gsub('::','_').underscore
      [namespace, @table_name].reject {|s| s.nil? || s.empty?}.join(namespace_separator)
    end

    def namespace(*args)
      case args.size
      when 0
        get_namespace
      when 1
        set_namespace(args[0])
      end
    end

    def get_namespace
      return @namespace if defined?(@namespace)
      @namespace = Dynomite.config.namespace || Dynomite.config.default_namespace
    end

    def set_namespace(value)
      @namespace = value
    end

    def namespace_separator
      Dynomite.config.namespace_separator || '_'
    end
  end
end
