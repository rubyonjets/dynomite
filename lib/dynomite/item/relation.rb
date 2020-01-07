class Dynomite::Item
  # Builds up the query with methods like where and eventually executes Query or Scan.
  class Relation
    include Enumerable

    def initialize(source)
      @source = source
    end

    def where(args)
      self
    end

    def all
    end
  end
end
