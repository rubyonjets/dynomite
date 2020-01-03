module Dynomite
  module Associations
    class HasOne
      include SingleAssociation

      private

      # Find the target association, always a :belongs_to association. Uses either options[:inverse_of] or the source class name
      # and default parsing to return the most likely name for the target association.
      def target_association
        key_name = options[:inverse_of] || source.class.to_s.singularize.underscore.to_sym
        guess = target_class.associations[key_name]
        return nil if guess.nil? || guess[:type] != :belongs_to

        association_method_name(key_name)
      end
    end
  end
end
