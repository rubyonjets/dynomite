class Dynomite::Item::Query::Relation
  # Builds up the query with methods like where and eventually executes Query or Scan.
  module Chain
    def where(args={})
      @query[:where] << WhereGroup.new(self, args)
      self
    end
    alias :and :where

    def or(args={})
      @query[:where] << WhereGroup.new(self, args, or: true)
      self
    end

    def not(args={})
      @query[:where] << WhereGroup.new(self, args, not: true)
      self
    end

    def excluding(*args)
      ids = args.map do |object|
        object.is_a?(Dynomite::Item) ? object.id : object
      end
      self.not("id.in": ids)
    end

    def scan_index_forward(value=true)
      @query[:scan_index_forward] = value
      self
    end

    def scan_index_backward(value=true)
      scan_index_forward(!value)
    end

    # The default limit for both Scan and Query in Amazon DynamoDB is 1 MB of data read.
    # It'll stop per api call regardless of the limit you set once it hits 1MB.
    def limit(value)
      @query[:limit] = value
      self
    end

    # Product.where(category: "Electronics").project("id, category").first
    def project(*fields)
      @query[:projection_expression] = fields
      self
    end
    alias projection_expression project

    # Disable use of index and query method. Force a scan method
    def force_scan
      @query[:force_scan] = true
      self
    end

    # Note consistent read it supported with GSI.
    # You may want to use force_scan if really need a consistent read.
    def consistent_read(value=true)
      @query[:consistent_read] = value
      self
    end
    alias consistent consistent_read

    def exclusive_start_key(hash)
      @query[:exclusive_start_key] = hash
      self
    end
    alias start_from exclusive_start_key
    alias start_at exclusive_start_key
    alias start exclusive_start_key

    # Could add some magically behavior to strip off the -index if the index name is 3 characters long.
    # but think that's even more obscure.
    #
    # suffix allows for shorter syntax:
    #
    #    index_name('created_at') vs index_name('created_at-index')
    #
    # Note: Tried using the shorter index method name but it seems to conflict an index method.
    # Even though Enumerable has an index method, it doesn't seem to be the one thats conflicting.
    # It's somewhere else.
    def index_name(name, suffix: 'index')
      name = [name, suffix].compact.join('-') if !name.ends_with?('index') && suffix
      @query[:index_name] = name.to_s
      self
    end

    def warn_on_scan(value=true)
      @warn_on_scan = value
      self
    end

    def attribute_exists(path)
      @query[:attribute_exists] << path
      self
    end

    def attribute_not_exists(path)
      @query[:attribute_not_exists] << path
      self
    end

    def attribute_type(path, type)
      @query[:attribute_type] << {path: path, type: type}
      self
    end

    # This is a function that accepts a path and a value.
    # This is different from the comparision operator. IE: ""
    def begins_with(path, substr)
      @query[:begins_with] << {path: path, substr: substr}
      self
    end

    def contains(path, substr)
      @query[:contains] << {path: path, substr: substr}
      self
    end

    def size_fn(path, size)
      @query[:size_fn] << {path: path, size: size}
      self
    end
  end
end
