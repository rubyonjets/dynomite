module Dynomite::Item::Query
  class Executer
    include Dynomite::Client

    def scan(params={})
      # params[:limit] = 1
      Enumerator.new do |y|
        last_evaluated_key = :start
        while last_evaluated_key
          if last_evaluated_key && last_evaluated_key != :start
            params[:exclusive_start_key] = last_evaluated_key
          end
          resp = db.scan(params)
          y.yield(resp)
          last_evaluated_key = resp.last_evaluated_key
        end
      end
    end
  end
end
