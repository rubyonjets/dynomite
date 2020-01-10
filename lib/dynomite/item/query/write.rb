module Dynomite::Item::Query
  module Write
    extend ActiveSupport::Concern

    # Not using method_missing to allow usage of dot notation and assign
    # @attrs because it might hide actual missing methods errors.
    # DynamoDB attrs can go many levels deep so it makes less make sense to
    # use to dot notation.

    def save(options={})
      options.reverse_merge!(validate: true)
      return false if options[:validate] && !valid?

      if new_record?
        run_callbacks(:create) do
          run_callbacks(:save) do
            Save.call(self, options)
          end
        end
      else
        run_callbacks(:save) do
          Save.call(self, options)
        end
      end
    end
    alias_method :replace, :save

    # Similar to save, but raises an error on failed validation.
    def save!(attrs={})
      raise Dynomite::Errors::ValidationError, "Validation failed: #{errors.full_messages.join(', ')}" unless replace(attrs)
    end
    alias_method :replace!, :save!

    def destroy(options={})
      run_callbacks(:destroy) do
        Destroy.call(self, options)
      end
    end

    def delete(options={})
      self.class.delete(@attrs[:id], options)
    end

    class_methods do
      def create(attrs={})
        item = new(attrs)
        item.save
        item
      end

      # Two ways to use the delete method:
      #
      # 1. Specify the key as a String. In this case the key will is the partition_key set on the model.
      #
      #   MyModel.destroy("728e7b5df40b93c3ea6407da8ac3e520e00d7351")
      #
      # 2. Specify the key as a Hash, you can arbitrarily specific the key structure this way
      #
      #   MyModel.destroy(id: "728e7b5df40b93c3ea6407da8ac3e520e00d7351")
      #
      # options can be used to specific condition_expression or expression_attribute_values.
      def delete(obj, options={})
        key = if obj.is_a?(String)
                { partition_key => obj }
              else # it should be a Hash
                obj
              end

        params = {
          table_name: table_name,
          key: key
        }
        # In case you want to specify condition_expression or expression_attribute_values
        params = params.merge(options)
        db.delete_item(params) # resp
      end
    end
  end
end
