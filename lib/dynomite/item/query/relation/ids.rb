class Dynomite::Item::Query::Relation
  module Ids
    def pluck(*names)
      project(*names)
      super # provided by Ruby Enumerable
    end

    def ids
      project(:id).each.map(&:id).to_a
    end

    def exists?(args={})
      !!limit(1).first
    end

    # Surprisingly, Enumberable does not provide empty?
    def empty?
      !exists?
    end
  end
end
