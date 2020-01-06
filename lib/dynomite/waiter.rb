module Dynomite
  class Waiter
    include Client

    def wait(table_name)
      Dynomite.logger.info "Waiting for #{table_name} table to be ready."
      status = nil
      # resp.table.table_status #=> String, one of:
      # CREATING UPDATING DELETING ACTIVE INACCESSIBLE_ENCRYPTION_CREDENTIALS ARCHIVING ARCHIVED
      until status == "ACTIVE" do
        resp = db.describe_table(table_name: table_name)
        status = resp.table.table_status
        puts "status #{status}"
        print '.'
        sleep 5
      end
      puts
    end
  end
end
