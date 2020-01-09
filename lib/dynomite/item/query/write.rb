module Dynomite::Item::Query
  module Write
    extend ActiveSupport::Concern

    # Not using method_missing to allow usage of dot notation and assign
    # @attrs because it might hide actual missing methods errors.
    # DynamoDB attrs can go many levels deep so it makes less make sense to
    # use to dot notation.

    def save(attrs={})
      saved = nil
      run_callbacks(:save) do
        @attrs = @attrs.deep_merge(attrs)

        # valid? method comes from ActiveModel::Validations
        if respond_to? :valid?
          return false unless valid?
        end

        saved = self.class.save(@attrs)
      end
      self.attrs(saved.attrs) # refresh attrs because it now has the id
      self
    end
    alias_method :replace, :save

    # Similar to replace, but raises an error on failed validation.
    # Works that way only if ActiveModel::Validations are included
    def save!(attrs={})
      raise ValidationError, "Validation failed: #{errors.full_messages.join(', ')}" unless replace(attrs)
    end
    alias_method :replace!, :save!

    def delete
      self.class.delete(@attrs[:id]) if @attrs[:id]
    end

    class_methods do
      def save(attrs)
        # Automatically adds some attributes:
        #   partition key unique id
        #   created_at and updated_at timestamps. Timestamp format from AWS docs: http://amzn.to/2z98Bdc
        defaults = {
          partition_key => Digest::SHA1.hexdigest([Time.now, rand].join)
        }
        attrs = defaults.merge!(attrs)
        attrs["created_at"] ||= Time.now
        attrs["updated_at"] = Time.now

        params = {
          table_name: table_name,
          item: attrs
        }
        params = Dynomite::Item::Typecaster.dump(params)
        Dynomite.logger.debug("put_item params: #{params}")
        # put_item full replaces the item
        db.put_item(params)
        # Note: The resp does not contain the attrs.

        # Return item instance
        item = new(attrs)
        item.new_record = false
        item
      end
      alias_method :replace, :save

      # Two ways to use the delete method:
      #
      # 1. Specify the key as a String. In this case the key will is the partition_key set on the model.
      #
      #   MyModel.delete("728e7b5df40b93c3ea6407da8ac3e520e00d7351")
      #
      # 2. Specify the key as a Hash, you can arbitrarily specific the key structure this way
      #
      #   MyModel.delete(id: "728e7b5df40b93c3ea6407da8ac3e520e00d7351")
      #
      # options is provided in case you want to specific condition_expression or
      # expression_attribute_values.
      def delete(key_object, options={})
        if key_object.is_a?(String)
          key = {
            partition_key => key_object
          }
        else # it should be a Hash
          key = key_object
        end

        params = {
          table_name: table_name,
          key: key
        }
        # In case you want to specify condition_expression or expression_attribute_values
        params = params.merge(options)

        db.delete_item(params) # resp
      end

      def create(attrs={})
        item = new(attrs)
        item.save
        item
      end
    end
  end
end
