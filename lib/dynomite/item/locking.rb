class Dynomite::Item
  module Locking
    extend ActiveSupport::Concern

    included do
      class_attribute :locking_field_name
    end

    class_methods do
      def enable_locking(field_name=:lock_version)
        class_eval do
          field field_name, type: :integer
          self.locking_field_name = field_name
          before_save :increment_lock_version
        end
      end
      alias enable_optimistic_locking enable_locking
      alias locking_field enable_locking

      def locking_enabled?
        locking_field_name.present?
      end
    end

    def increment_lock_version
      return unless changed?
      reader = self.class.locking_field_name
      setter = "#{reader}="
      send(setter, 0) if send(reader).nil?
      send(setter, send(reader) + 1)
    end

    # Tricky: Must use dot notation for dirty tracking so old values are stored in case of a
    # exceptional failure in the DynamoDB API put_item call in write/save.rb
    # Example:
    #
    #   post.update_attribute(:title, nil) # update attribute bypasses validations
    #
    #   AWS Error:
    #
    # The AttributeValue for a key attribute cannot contain an empty string value.
    # IndexName: title-index, IndexKey: title (Aws::DynamoDB::Errors::ValidationException)
    #
    # This allows the old value to be restored. And then the next update with a corrected
    # title value saves successfully.
    #
    def reset_lock_version_was
      reader = self.class.locking_field_name
      setter = "#{reader}="
      send(setter, send("#{reader}_was"))
    end
  end
end
