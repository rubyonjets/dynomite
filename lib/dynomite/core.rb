require 'logger'

module Dynomite::Core
  # Ensures trailing slash
  # Useful for appending a './' in front of a path or leaving it alone.
  # Returns: '/path/with/trailing/slash/' or './'
  @@app_root = nil
  def app_root
    return @@app_root if @@app_root
    @@app_root = ENV['APP_ROOT'] || ENV['JETS_ROOT'] || ENV['RAILS_ROOT']
    @@app_root = '.' if @@app_root.nil? || @app_root == ''
    @@app_root = "#{@@app_root}/" unless @@app_root.ends_with?('/')
    @@app_root
  end

  @@logger = nil
  def logger
    return @@logger if @@logger
    @@logger = Logger.new($stderr)
  end

  def logger=(value)
    @@logger = value
  end
end
