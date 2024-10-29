require "aws-sdk-dynamodb"
require "erb"
require "fileutils"
require "json"
require "yaml"

module Dynomite
  module Client
    extend ActiveSupport::Concern
    delegate :client, :desc_table, :show_request, :show_response,
             :warn_scan, :log_debug, :logger,
             to: :class

    class_methods do
      extend Memoist

      @@client = nil
      def client
        return @@client if @@client

        endpoint = Dynomite.config.endpoint
        check_dynamodb_local!(endpoint)

        # Normally, do not set the endpoint to use the current configured region.
        # Probably want to stay in the same region anyway for db connections.
        #
        # List of regional endpoints: https://docs.aws.amazon.com/general/latest/gr/rande.html#ddb_region
        # Example:
        #   endpoint: https://dynamodb.us-east-1.amazonaws.com
        options = endpoint ? { endpoint: endpoint } : {}
        log_level = Dynomite.config.log_level.to_s
        # https://aws.amazon.com/blogs/developer/logging-requests/
        # https://github.com/aws/aws-sdk-ruby/blob/249a0b34d0014dda50ecc8a09cd58e75e64b3ea4/gems/aws-sdk-core/lib/aws-sdk-core/log/formatter.rb#L212
        if log_level == "debug"
          options[:logger] = Dynomite.logger
          options[:log_formatter] = Aws::Log::Formatter.colored # default short colored
        end
        @@client ||= Aws::DynamoDB::Client.new(options)
      end

      # useful for specs
      def client=(client)
        @@client = client
      end

      def desc_table(table_name)
        client.describe_table(table_name: table_name).table
      end
      memoize :desc_table

      def show_request(params)
        logger.info("REQUEST: #{JSON.dump(params)}")
      end

      def show_response(resp)
        logger.info("RESPONSE: #{JSON.dump(resp)}")
      end

      # When endoint has been configured to point at dynamodb local: localhost:8000
      # check if port 8000 is listening and timeout quickly. Or else it takes a
      # for DynamoDB local to time out, about 10 seconds...
      # This wastes less of the users time.
      def check_dynamodb_local!(endpoint)
        return unless endpoint
        endpoint_uri = URI.parse(endpoint)

        return unless endpoint_uri.port == 8000

        open = port_open?(endpoint_uri.host, endpoint_uri.port, 0.2)
        unless open
          raise "You have configured your app to use DynamoDB local, but it is not running.  Please start DynamoDB local. Example: brew cask install dynamodb-local && dynamodb-local"
        end
      end

      # Thanks: https://gist.github.com/ashrithr/5305786
      def port_open?(ip, port, seconds=1)
        # => checks if a port is open or not
        Timeout::timeout(seconds) do
          begin
            TCPSocket.new(ip, port).close
            true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
            false
          end
        end
      rescue Timeout::Error
        false
      end

      def warn_scan(message, show: nil)
        warn_on_scan = show.nil? ? Dynomite.config.warn_on_scan : show
        return unless warn_on_scan
        message += <<~EOL
          You can disable this warning by setting Dynomite.config.warn_on_scan: false
        EOL
        logger.info(message)
        logger.info("Called from: #{call_line}") if call_line
      end

      def call_line
        caller.find { |l| l.include?(Dir.pwd) }
      end

      def log_debug(params)
        return unless ENV['DYNOMITE_DEBUG']

        call_location = caller_locations[1].to_s # IE: dynomite/item/query/relation.rb:62:in `block in raw_pages'
        return if call_location.blank? # edge cases
        method_name = call_location.split('`').last.split(" ").last # IE: raw_pages'
        method_name.gsub!("'", "") # IE: raw_pages

        logger.info "#{self}##{method_name}" # IE: Dynomite::Item::Query::Relation#raw_pages
        pp params
      end

      def logger
        Dynomite.logger
      end
    end
  end
end
