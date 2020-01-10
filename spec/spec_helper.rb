ENV["DYNOMITE_TEST"] = '1'
ENV['DYNOMITE_CONFIG'] = 'spec/fixtures/app_root/config/dynamodb.yml'
ENV['DYNOMITE_ENV'] = 'test'
ENV['JETS_ROOT'] = 'spec/fixtures'
# Ensures aws api never called. Fixture home folder does not contain ~/.aws/credentials
ENV['HOME'] = File.join(Dir.pwd,'spec/fixtures/home')

require "byebug"
root = File.expand_path("../", File.dirname(__FILE__))
require "#{root}/lib/dynomite"

# Not currently using dynamodb-local for specs but configure the endpoint to it just in case
Dynomite.configure do |config|
  config.endpoint = "http://localhost:8000"
end

module Helper
  def execute(cmd)
    puts "Running: #{cmd}" if show_command?
    out = `#{cmd}`
    puts out if show_command?
    out
  end

  # Added SHOW_COMMAND because DEBUG is also used by other libraries like
  # bundler and it shows its internal debugging logging also.
  def show_command?
    ENV['DEBUG'] || ENV['SHOW_COMMAND']
  end
end

RSpec.configure do |c|
  c.include Helper
end
