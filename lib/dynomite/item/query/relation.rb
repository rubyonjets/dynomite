module Dynomite::Item::Query
  # Builds up the query with methods like where and eventually executes Query or Scan.
  class Relation
    extend Memoist
    include Dynomite::Client
    include Enumerable
    include Chain
    include Math
    include Ids
    include Delete

    attr_accessor :index, :query, :source
    def initialize(source)
      @source = source # source is the model class. IE: Post User etc
      @query = {
        where: [],
        attribute_exists: [],
        attribute_not_exists: [],
        attribute_type: [],
        begins_with: [],
        contains: [],
        size_fn: [],
      }
      @index = 0
    end

    # Enumerable provides .to_a, add force so it's more like lazy Enumerable.
    # Also, not using: `alias load to_a` because load is Enumerable private method
    # Instead user should use force or eager. Docs:
    # https://docs.ruby-lang.org/en/master/Enumerator/Lazy.html
    # https://www.rubydoc.info/stdlib/core/Enumerator/Lazy
    alias size count
    alias force to_a

    def each(&block)
      items.each(&block)
    end

    def items
      pages.flat_map { |i| i } # flat_map flattens the Lazy Enumerator since yielding pages
    end
    private :items

    def pages
      raw_pages.map do |raw_page|
        raw_page.items.map.map(&method(:build_item))
      end
    end
    alias each_page pages

    def raw_pages
      params = to_params
      # total_limit is the total limit across all pages
      # For the AWS API call itself use the default limit and allow AWS to scan 1MB for page
      total_limit = params.delete(:limit)
      total_count = 0
      Enumerator.new do |y|
        last_evaluated_key = :start
        while last_evaluated_key
          if last_evaluated_key && last_evaluated_key != :start
            params[:exclusive_start_key] = last_evaluated_key
          end

          meth = params[:key_condition_expression] ? :query : :scan
          log_debug(params)
          raw_warn_scan if meth == :scan
          response = client.send(meth, params) # scan or query
          records = response.items.map { |i| build_item(i, run_callback: false) }
          y.yield(response, records)

          # Track total_count across pages. If limit is set, then stop when we reach it.
          # Since limit can be greater than each API response paged size.
          total_count += response.items.size
          break if total_limit && total_count >= total_limit

          last_evaluated_key = response.last_evaluated_key
        end
      end.lazy
    end
    alias each_raw_page raw_pages

    def build_item(i, run_callback: true)
      item = @source.new(i) # IE: Post.new(i)
      item.new_record = false
      item.run_callbacks :find if run_callback
      item
    end

    # Enumerable provides .first but does not provide .last
    # Note, cannot use:
    #     scan_index_forward(false).limit(1).first
    # Since that will not work for queries that do not have a sort key.
    # Users need to use query directly if they want to find the last item more efficiently.
    def last
      warn_scan <<~EOL
        WARN: Dynomite::Item::Query::Relation#last is slow.
        Consider using query directly if you have a primary key that as a sort key.
      EOL
      to_a.last # force load of lazy enumerator. slow
    end

    def to_params
      Params.new(self, @source).to_h
    end

    # Allows all to chain itself. This allows.
    #
    #   Post.where(category: "Electronics").all
    #   Post.limit(1).all
    #   Post.all.all         # also works, side effect
    #
    def all
      self
    end

    def raw_warn_scan
      warn_on_scan = @warn_on_scan.nil? ? Dynomite.config.warn_on_scan : @warn_on_scan
      return unless warn_on_scan
      warn_scan <<~EOL
        WARN: Scanning detected. It's recommended to not use scan. It can be slow.
        Scanning table: #{@source.table_name}
        Try creating a LSI or GSI index so dynomite can use query instead.
        Docs: https://rubyonjets.com/docs/database/dynamodb/indexing/
      EOL
    end
  end
end
