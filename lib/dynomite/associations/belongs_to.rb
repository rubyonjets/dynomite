module Dynomite
  # The belongs_to association. For belongs_to, we reference only a single target instead of multiple records; that target is the
  # item to which the association item is associated.
  module Associations
    class BelongsTo
      include SingleAssociation

      def declaration_field_type
        if options[:foreign_key]
          target_class.attributes[target_class.partition_key][:type]
        else
          :set
        end
      end

      private

      # Find the target association, either has_many or has_one. Uses either options[:inverse_of] or the source class name and default parsing to
      # return the most likely name for the target association.
      def target_association
        has_many_key_name = options[:inverse_of] || source.class.to_s.underscore.pluralize.to_sym
        has_one_key_name = options[:inverse_of] || source.class.to_s.underscore.to_sym
        unless target_class.associations[has_many_key_name].nil?
          method_name = association_method_name(has_many_key_name)
          return method_name if target_class.associations[has_many_key_name][:type] == :has_many
        end

        unless target_class.associations[has_one_key_name].nil?
          method_name = association_method_name(has_one_key_name)
          return method_name if target_class.associations[has_one_key_name][:type] == :has_one
        end
      end
    end
  end
end
