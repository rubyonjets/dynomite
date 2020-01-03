module Dynomite::Item::Query
  class Params
    extend Memoist
    include Dynomite::Types
    include Helpers

    attr_reader :source
    delegate :partition_key_field, :sort_key_field, :table_name, to: :source

    def initialize(relation, source)
      @relation, @source = relation, source
      @query = relation.query
    end

    # key condition
    # 1. primary key highest precedence
    # 2. index
    # filter expression
    # 1. if field used in key condition
    # 2. then don’t use in filter expression
    # attributes
    # 1. all values will be mapped over
    # 2. will be in key condition or filter expression
    # index name
    # 1. if key condition set
    # 2. unless primary key
    def to_h
      # set @index first. used throughout class
      @index = index_finder.find(@query[:index_name])
      @index = nil if scan_required?(@index) # IE: NOT operator on where field

      # must build in this order
      build_key_condition_expression if @index # must build first
      build_filter_expression
      build_attributes                         # must build last

      @params = {
        expression_attribute_names: @expression_attribute_names,    # both scan and query
        expression_attribute_values: @expression_attribute_values,  # both scan and query
        table_name: table_name,
      }

      @params[:filter_expression] = @filter_expression # both scan and query
      @params[:key_condition_expression] = @key_condition_expression # query only. required

      # primary index does not have a name but they are added to the @key_condition_expression
      @params[:index_name] = @index.index_name if @index && !@index.primary? # both scan and query can use index

      @params.reject! { |k,v| v.blank? }

      # scan_index_forward after reject! so it's not removed
      @params[:scan_index_forward] = !!@query[:scan_index_forward] if @query.key?(:scan_index_forward)
      @params[:limit] = @query[:limit] if @query.key?(:limit)
      @params[:projection_expression] = projection_expression if projection_expression
      @params[:consistent_read] = @query[:consistent_read] if @query.key?(:consistent_read)
      @params[:exclusive_start_key] = @query[:exclusive_start_key] if @query.key?(:exclusive_start_key)

      log_index_info
      @params
    end

    def projection_expression
      return if @query[:projection_expression].nil?
      projection_expression = normalize_project_expression(@query[:projection_expression])
      projection_expression.map do |field|
        '#'+field
      end.join(", ")
    end

    # key_condition_expression is the most restrictive way to query.
    # It requires the primary key and sort key.
    # It also requires either the primary key or an index.
    # Otherwise, we do not set it at all.
    #
    # So we'll build this first and then add the other expressions to it.
    #
    # key condition
    # 1. primary key highest precedence
    # 2. index
    # 3. track fields used
    def build_key_condition_expression
      key_condition = KeyCondition.new(@relation, @index, partition_key_field, sort_key_field)
      @key_condition_expression = key_condition.expression
    end

    def build_filter_expression
      filter = Filter.new(@relation, @index)
      @filter_expression = filter.expression
    end

    def build_attributes
      expression_attribute = ExpressionAttribute.new(@relation)
      @expression_attribute_names = expression_attribute.names
      @expression_attribute_values = expression_attribute.values
    end

    def log_index_info
      return unless ENV['DYNOMITE_DEBUG']

      if @index
        Dynomite.logger.info "Index used #{@index.index_name}"
      elsif @params[:@expression_attribute_names]
        attributes_list = @params[:@expression_attribute_names].values.join(", ")
        Dynomite.logger.info "Not using index. None found for the attributes: #{attributes_list}"
      else
        Dynomite.logger.info "Not using index. @params #{@params.inspect}"
      end
    end

    def index_finder
      Dynomite::Item::Indexes::Finder.new(@source, @query)
    end
    memoize :index_finder
  end
end