require 'logger'

module DynamodbModel::Util
  # Ensures trailing slash
  # Useful for appending a './' in front of a path or leaving it alone.
  # Returns: '/path/with/trailing/slash/' or './'
  @@app_root = nil
  def app_root
    return @@app_root if @@app_root
    @@app_root = ENV['JETS_ROOT'].to_s
    @@app_root = '.' if @@app_root == ''
    @@app_root = "#{@@app_root}/" unless @@app_root.ends_with?('/')
    @@app_root
  end
end
