module Dynomite
  class Error < StandardError
    class RecordNotFound < Error; end
    class ReservedWord < Error; end
    class Validation < Error; end
  end
end
