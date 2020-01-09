class Dynomite::Item
  module Query
    extend ActiveSupport::Concern
    include Read
    include Write
  end
end
