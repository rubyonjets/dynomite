$:.unshift(File.expand_path("../", __FILE__))
require "dynomite/version"
require "rainbow/ext/string"

module Dynomite
  ATTRIBUTE_TYPES = {
    'string' => 'S',
    'number' => 'N',
    'binary' => 'B',
    's' => 'S',
    'n' => 'N',
    'b' => 'B',
  }

  autoload :Migration, "dynomite/migration"
  autoload :Dsl, "dynomite/dsl"
  autoload :DbConfig, "dynomite/db_config"
  autoload :Item, "dynomite/item"
  autoload :Core, "dynomite/core"
  autoload :Erb, "dynomite/erb"
  autoload :Log, "dynomite/log"
  autoload :Errors, "dynomite/errors"

  extend Core
end
