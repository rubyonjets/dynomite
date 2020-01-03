class Dynomite::Item
  module Id
    extend ActiveSupport::Concern

    included do
      field :id
      before_save :set_id
    end

    def set_id
      return if self.class.disable_id?
      self.id ||= generate_id
    end

    def generate_id
      "#{id_prefix}-#{SecureRandom.alphanumeric(16)}"
    end

    def id_prefix
      self.class.id_prefix_value
    end

    class_methods do
      def disable_id?
        !!@disable_id
      end

      def disable_id!
        @disable_id = true
      end

      def id_prefix(value=nil)
        if value.nil?
          self.id_prefix_value
        else
          self.id_prefix_value = value
        end
      end
    end
  end
end
