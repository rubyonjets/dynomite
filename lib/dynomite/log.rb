module Dynomite::Log
  def self.included(base)
    base.extend(ClassMethods)
  end

  def log(msg)
    self.class.log(msg)
  end

  module ClassMethods
    def log(msg)
      Dynomite.logger.info(msg)
    end
  end
end
