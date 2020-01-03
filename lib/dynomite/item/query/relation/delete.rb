class Dynomite::Item::Query::Relation
  module Delete
    def delete_all
      # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#batch_write_item-instance_method
      # A single call to BatchWriteItem can transmit up to 16MB of data over the network,
      # consisting of up to 25 item put or delete operations.
      batch_limit = 25 # max batch size for batch_write_item
      each_page.each do |page|
        page.each_slice(batch_limit) do |slice|
          primary_keys = slice.map(&:primary_key)
          delete_requests = primary_keys.map do |primary_key|
            {
              delete_request: {
                key: primary_key,
              },
            }
          end
          request_items = { @source.table_name => delete_requests }
          client.batch_write_item(request_items: request_items)
        end
      end
    end

    def destroy_all
      each(&:destroy)
    end

    # require args
    def delete_by(args)
      where(args).delete_all
    end

    # require args
    def destroy_by(args)
      where(args).destroy_all
    end
  end
end
