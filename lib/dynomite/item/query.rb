class Dynomite::Item
  module Query
    extend ActiveSupport::Concern
    include Partiql
    include Delegates
  end
end
