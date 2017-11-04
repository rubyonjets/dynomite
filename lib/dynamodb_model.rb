$:.unshift(File.expand_path("../", __FILE__))
require "dynamodb_model/version"

module DynamodbModel
  autoload :Migration, "dynamodb_model/migration"
  autoload :Dsl, "dynamodb_model/dsl"
  autoload :DbConfig, "dynamodb_model/db_config"
  autoload :Item, "dynamodb_model/item"
end
