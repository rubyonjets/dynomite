module Dynomite
  class Waiter
    include Client

    def wait(table_name)
      Dynomite.logger.info "Waiting for #{table_name} table to be ready."
      statuses = [:initial]
      until statuses.all? { |s| s == "ACTIVE" } do
        resp = db.describe_table(table_name: table_name)

        table = resp.table
        # table_status: CREATING UPDATING DELETING ACTIVE INACCESSIBLE_ENCRYPTION_CREDENTIALS ARCHIVING ARCHIVED
        table_status = table.table_status
        statuses = [table_status]
        # index_status: CREATING UPDATING DELETING ACTIVE
        indexes = table.global_secondary_indexes || []
        statuses += indexes.map { |i| i.index_status }
        # puts "statuses #{statuses}"
        print '.'
        sleep 5
      end
      puts
    end
  end
end
