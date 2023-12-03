module Dynomite::Item::Write
  class PutItem < Base
    def call
      # typecaster will convert the attrs to the correct types for saving to DynamoDB
      item = Dynomite::Item::Typecaster.new(@model).dump(permitted_attrs)
      @params = {
        table_name: @model.class.table_name,
        item: item
      }
      @params.merge!(check_unique_params)
      @params.merge!(locking_params)

      # put_item replaces the item fully. The resp does not contain the attrs.
      log_debug(@params)
      begin
        client.put_item(@params)
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException => e
        handle_conditional_check_failed_exception(e)
      rescue Aws::DynamoDB::Errors::ValidationException => e
        @model.reset_lock_version_was if @model.class.locking_enabled?
        raise
      end

      @model.new_record = false
      @model
    end

    def permitted_attrs
      field_names = @model.class.field_names.map(&:to_sym)
      assigned_fields = @model.attrs.keys.map(&:to_sym)
      undeclared_fields = assigned_fields - field_names
      declared_fields = field_names - assigned_fields

      case Dynomite.config.undeclared_field_behavior.to_sym
      when :allow
        @model.attrs # allow
      when :silent
        @model.attrs.slice(*field_names)
      when :error
        unless undeclared_fields.empty?
          raise Dynomite::Error::UndeclaredFields.new("ERROR: Saving undeclared fields not allowed: #{undeclared_fields} for #{@model.class}")
        end
      else # warn
        unless undeclared_fields.empty?
          logger.info "WARNING: Not saving undeclared fields: #{undeclared_fields}. Saving declared fields only: #{declared_fields} for #{@model.class}"
        end
        @model.attrs.slice(*field_names)
      end
    end

    def handle_conditional_check_failed_exception(exception)
      if @params[:condition_expression] == check_unique_condition
        raise Dynomite::Error::RecordNotUnique.new(not_unique_message)
      else # currently only other case is locking
        raise Dynomite::Error::StaleObject.new(exception.message)
      end
    end

    def not_unique_message
      primary_key_attrs = permitted_attrs.stringify_keys.slice(@model.partition_key_field, @model.sort_key_field).symbolize_keys
      primary_key_found = primary_key_attrs.keys.map(&:to_s)
      "A #{@model.class.name} with the primary key #{primary_key_attrs} already exists"
    end

    def check_unique_params
      if @model.new_record? && !@options[:put]
        @params.merge!(condition_expression: check_unique_condition)
      else
        {}
      end
    end

    # https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.ConditionExpressions.html#Expressions.ConditionExpressions.PreventingOverwrites
    # Examples:
    #   attribute_not_exists(id)
    #   attribute_not_exists(category) AND attribute_not_exists(sku)
    def check_unique_condition
      condition_expression = @model.primary_key_fields.map do |field|
        "attribute_not_exists(#{field})"
      end.join(" AND ")
    end

    def locking_params
      return {} if @params[:condition_expression] # already set from check_unique_params
      return {} unless @model.class.locking_enabled?
      return {} if @model._touching
      field = @model.class.locking_field_name
      current_version = @model.send(field) # must use send, since it was set by send. fixes .touch method
      return {} if current_version == 1

      previous_version = current_version - 1 # since before_save increments it
      {
        condition_expression: "#lock_version = :lock_version",
        expression_attribute_names: {"#lock_version" => "lock_version"},
        expression_attribute_values: {":lock_version" => previous_version}
      }
    end
  end
end
