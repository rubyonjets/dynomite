$:.unshift(File.expand_path("../", __FILE__))
require "dynamodb_model/version"

module DynamodbModel
  ATTRIBUTE_TYPES = {
    'string' => 'S',
    'number' => 'N',
    'binary' => 'B',
    's' => 'S',
    'n' => 'N',
    'b' => 'B',
  }

  autoload :Migration, "dynamodb_model/migration"
  autoload :Dsl, "dynamodb_model/dsl"
  autoload :DbConfig, "dynamodb_model/db_config"
  autoload :Item, "dynamodb_model/item"
  autoload :Core, "dynamodb_model/core"
  autoload :Erb, "dynamodb_model/erb"
  autoload :Log, "dynamodb_model/log"

  extend Core
end
