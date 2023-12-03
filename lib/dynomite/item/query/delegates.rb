module Dynomite::Item::Query
  module Delegates
    extend ActiveSupport::Concern

    # Makes Relation methods like where, or, not, limit, etc available as model class methods.
    # Post.where(category: 'ruby').limit(10)
    class_methods do
      delegates = Relation::Chain.public_instance_methods(false) +
                  Relation::Math.public_instance_methods(false) +
                  Relation::Ids.public_instance_methods(false) +
                  Relation::Delete.public_instance_methods(false)
      delegates.each do |method|
        delegate method, to: :all
      end

      # Most of thoese methods are free from Enumerable, except: last
      delegate :last, :any?, :many?, :each_page, :pages, :raw_pages,
               to: :all

      # point of entry for query
      def all
        relation = Relation.new(self)
        relation.where(type: name) if sti_enabled?
        relation
      end
    end
  end
end
