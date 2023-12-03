class Dynomite::Migration::Dsl
  module ProvisionedThroughput
    def billing_mode(v)
      @billing_mode = v
      @provisioned_throughput = nil if @billing_mode.to_s.upcase == "PAY_PER_REQUEST"
    end

    # t.provisioned_throughput(1) # both
    # t.provisioned_throughput(1,1) # read, write
    # t.provisioned_throughput({
    #   read_capacity_units: 1,
    #   write_capacity_units: 1
    # }
    def provisioned_throughput(*args)
      if args.size == 0 # reader method
        @provisioned_throughput # early return
      elsif args.first.is_a?(Hash)
        # @provisioned_throughput_set_called useful for update_table
        # only provide a provisioned_throughput settings if explicitly called for update_table
        @provisioned_throughput_set_called = true
        # Case:
        # provisioned_throughput(
        #   read_capacity_units: 1,
        #   write_capacity_units: 1
        # )
        @provisioned_throughput = arg.first # set directly
      else  # assume parameter is an Integer or [Integer, Integer]
        # Case: provisioned_throughput(1)
        # Case: provisioned_throughput(1, 1)
        read_capacity_units, write_capacity_units = args
        @provisioned_throughput = {
          read_capacity_units: read_capacity_units,
          write_capacity_units: write_capacity_units || read_capacity_units,
        }
      end
    end
  end
end
