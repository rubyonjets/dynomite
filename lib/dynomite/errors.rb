module Dynomite
  module Errors
    class ValidationError < StandardError
      def initialize(msg)
        super
      end
    end

    class ReservedWordError < StandardError
      def initialize(msg)
        super
      end
    end
  end
end
