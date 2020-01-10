require "aws-sdk-dynamodb"
require "erb"
require "fileutils"
require "json"
require "yaml"

module Dynomite
  module Client
    def self.included(base)
      base.extend(ClassMethods)
    end

    def db
      self.class.db
    end

    def show_request(params)
      self.class.show_request(params)
    end

    def show_response(resp)
      self.class.show_response(resp)
    end

    module ClassMethods
      @@db = nil
      def db
        return @@db if @@db

        endpoint = Dynomite.config.endpoint
        check_dynamodb_local!(endpoint)

        # Normally, do not set the endpoint to use the current configured region.
        # Probably want to stay in the same region anyway for db connections.
        #
        # List of regional endpoints: https://docs.aws.amazon.com/general/latest/gr/rande.html#ddb_region
        # Example:
        #   endpoint: https://dynamodb.us-east-1.amazonaws.com
        options = endpoint ? { endpoint: endpoint } : {}

        if ENV['DYNOMITE_DEBUG_LOG']
          formatter = Aws::Log::Formatter.new(':operation | Request :http_request_body | Response :http_response_body')
          options[:log_formatter] = formatter
          options[:log_level] = :debug
          options[:logger] = Dynomite.logger
        end

        @@db ||= Aws::DynamoDB::Client.new(options)
      end

      def show_request(params)
        Dynomite.logger.info("REQUEST: #{JSON.dump(params)}")
      end

      def show_response(resp)
        Dynomite.logger.info("RESPONSE: #{JSON.dump(resp)}")
      end

      # When endoint has been configured to point at dynamodb local: localhost:8000
      # check if port 8000 is listening and timeout quickly. Or else it takes a
      # for DynamoDB local to time out, about 10 seconds...
      # This wastes less of the users time.
      def check_dynamodb_local!(endpoint)
        return unless endpoint && endpoint.include?("8000")

        open = port_open?("127.0.0.1", 8000, 0.2)
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

      # useful for specs
      def db=(db)
        @@db = db
      end
    end
  end
end
