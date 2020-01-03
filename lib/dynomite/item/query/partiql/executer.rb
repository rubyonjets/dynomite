module Dynomite::Item::Query::Partiql
  class Executer
    include Dynomite::Client

    def initialize(source)
      @source = source # source is the model class. IE: Post User etc
    end

    # Execute PartiQL query
    #
    # AWS Docs:
    # - https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#execute_statement-instance_method
    # - https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ql-reference.select.html
    #
    # resp = client.execute_statement({
    #   statement: "PartiQLStatement", # required
    #   parameters: ["value"], # value <Hash,Array,String,Numeric,Boolean,IO,Set,nil>
    #   consistent_read: false,
    #   next_token: "PartiQLNextToken",
    #   return_consumed_capacity: "INDEXES", # accepts INDEXES, TOTAL, NONE
    #   limit: 1,
    #   return_values_on_condition_check_failure: "ALL_OLD", # accepts ALL_OLD, NONE
    # })
    def call(statement, parameters = {}, options = {})
      total_count = 0
      # total_limit is the total limit across all pages
      # For the AWS API call itself use the default limit and allow AWS to scan 1MB for page
      total_limit = parameters.delete(:limit)
      enumerator = Enumerator.new do |y|
        next_token = :start
        while next_token
          if next_token && next_token != :start
            options[:next_token] = next_token
          end

          params = { statement: statement }
          params[:parameters] = parameters unless parameters.empty?
          raw = options.delete(:raw)
          params.merge!(options)
          log_debug(params)
          resp = client.execute_statement(params)
          if raw
            y.yield(resp.items)
          else
            page = resp.items.map { |i| build_item(i) }
            y.yield(page)
          end

          # Track total_count across pages. If limit is set, then stop when we reach it.
          # Remember the limit is per page for each API call, not total.
          total_count += page.size
          break if total_limit && total_count >= total_limit

          next_token = resp.next_token
        end
      end
      if statement =~ /^SELECT/i
        enumerator.lazy.flat_map { |i| i } # lazy.flat_map flattens the array since yielding pages
        # Returns a lazy enumerator: #<Enumerator::Lazy: ...>
      else
        # For non-SELECT statements: INSERT, UPDATE, DELETE
        enumerator.first # call first to execute the query immediately
      end
    end

    def build_item(i)
      item = @source.new(i) # IE: Post.new(i)
      item.new_record = false
      item
    end
  end
end
