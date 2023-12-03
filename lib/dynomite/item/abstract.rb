class Dynomite::Item
  module Abstract
    extend ActiveSupport::Concern

    class_methods do
      def abstract?
        !!@abstract
      end

      def abstract!
        @abstract = true
      end
    end
  end
end
