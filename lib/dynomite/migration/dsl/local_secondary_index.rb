class Dynomite::Migration::Dsl
  class LocalSecondaryIndex < BaseSecondaryIndex
    def initialize(index_name=nil, &block)
      # Can only create local secondary index when creating a table
      super(:create, index_name, &block)
    end
  end
end
