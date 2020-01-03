module Dynomite::Item::Query::Params::Function
  class Contains < BeginsWith
    def query_key
      :contains # must be symbol
    end
  end
end
