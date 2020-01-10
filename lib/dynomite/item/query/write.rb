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

    # Similar to replace, but raises an error on failed validation.
    # Works that way only if ActiveModel::Validations are included
    def save!(attrs={})
      raise ValidationError, "Validation failed: #{errors.full_messages.join(', ')}" unless replace(attrs)
    end
    alias_method :replace!, :save!

    def destroy
      Destroy.call(self, options)
    end

    class_methods do
      def create(attrs={})
        item = new(attrs)
        item.save
        item
      end
    end
  end
end
