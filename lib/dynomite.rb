$:.unshift(File.expand_path("../", __FILE__))
require "active_support/core_ext/string"
require "dynomite/version"
require "rainbow/ext/string"

require "dynomite/autoloader"
Dynomite::Autoloader.setup

require "dynomite/reserved_words"

module Dynomite
  ATTRIBUTE_TYPES = {
    'string' => 'S',
    'number' => 'N',
    'binary' => 'B',
    's' => 'S',
    'n' => 'N',
    'b' => 'B',
  }

  extend Core
end
