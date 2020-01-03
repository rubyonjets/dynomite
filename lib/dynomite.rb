$:.unshift(File.expand_path("../", __FILE__))
require "active_support"
require "active_support/concern"
require "active_support/core_ext/hash"
require "active_support/core_ext/string"
require "dynomite/version"
require "memoist"
require "rainbow/ext/string"

require "dynomite/autoloader"
Dynomite::Autoloader.setup

require "dynomite/reserved_words"

module Dynomite
  extend Core
end

require "dynomite/engine" if defined?(Jets)
