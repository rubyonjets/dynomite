module Dynomite
  class Error < StandardError
    class InvalidPut < Error; end
    class PrimaryKeyChangedError < Error; end
    class RecordNotFound < Error; end
    class RecordNotUnique < Error; end
    class ReservedWord < Error; end
    class StaleObject < Error; end
    class UndeclaredFields < Error; end
    class Validation < Error; end
  end
end
