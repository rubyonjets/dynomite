module Dynomite
  class Waiter
    include Client

    def wait(table_name)
      logger.info "Waiting for #{table_name} table to be ready."
      statuses = [:initial]
      until statuses.all? { |s| s == "ACTIVE" } do
        resp = client.describe_table(table_name: table_name)

        table = resp.table
        # table_status: CREATING UPDATING DELETING ACTIVE INACCESSIBLE_ENCRYPTION_CREDENTIALS ARCHIVING ARCHIVED
        table_status = table.table_status
        statuses = [table_status]
        # index_status: CREATING UPDATING DELETING ACTIVE
        indexes = table.global_secondary_indexes || []
        statuses += indexes.map { |i| i.index_status }
        print '.'
        sleep pause_time
      end
      puts
    end

    def wait_for_delete(table_name)
      logger.info "Waiting for #{table_name} table to be deleted."
      begin
        client.describe_table(table_name: table_name)
        print '.'
        sleep pause_time
      rescue Aws::DynamoDB::Errors::ResourceNotFoundException => e
      end
      puts
    end

  private
    def pause_time
      1
    end
  end
end
