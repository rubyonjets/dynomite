module Dynomite
  class Migration
    include Item::WaiterMethods
    include Dynomite::Client
    include Helpers

    def up
      puts "Should defined an up method for your migration: #{self.class.name}"
    end

    def create_table(table_name, &block)
      execute(table_name, :create_table, &block)
    end

    def update_table(table_name, &block)
      execute(table_name, :update_table, &block)
    end

    def delete_table(table_name, &block)
      execute(table_name, :delete_table, &block)
    end

    def add_gsi(table_name, *args)
      update_table(table_name) do |t|
        t.add_gsi(*args)
      end
    end

    def remove_gsi(table_name, *args)
      update_table(table_name) do |t|
        t.remove_gsi(*args)
      end
    end

    def update_gsi(table_name, *args)
      update_table(table_name) do |t|
        t.update_gsi(*args)
      end
    end

    def update_time_to_live(table_name, time_to_live_specification={})
      table_name = table_name_with_namespace(table_name)
      client.update_time_to_live(
        table_name: table_name,
        time_to_live_specification: time_to_live_specification
      )
      # fast enough of an operation, no need to wait
    end
    alias update_ttl update_time_to_live

  private
    # execute with dsl params
    # table name is short name and params[:table_name] is full namespaced name
    def execute(table_name, method_name, &block)
      params = Dsl.new(method_name, table_name, &block).params

      puts "Running #{method_name} with:"
      pp params
      resp = client.send(method_name, params)
      namespaced_table_name = params[:table_name] # full: demo-dev_posts short: posts
      puts "DynamoDB Table: #{namespaced_table_name} Status: #{resp.table_description.table_status}"

      if method_name.to_sym == :delete_table # already sym, to_sym just in case
        waiter.wait_for_delete(params[:table_name])
      else # create_table or update_table
        waiter.wait(params[:table_name])
      end
    end
  end
end
