class Dynomite::Item
  module WaiterMethods
    extend ActiveSupport::Concern

    def waiter
      self.class.waiter
    end

    class_methods do
      extend Memoist

      def waiter
        Dynomite::Waiter.new
      end
      memoize :waiter
    end
  end
end
