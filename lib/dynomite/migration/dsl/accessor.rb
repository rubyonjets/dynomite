class Dynomite::Migration::Dsl
  module Accessor
    def dsl_accessor(*names)
      names.each do |name|
        define_dsl_accessor(name)
      end
    end

    def define_dsl_accessor(name)
      define_method(name) do |*args|
        if args.empty?
          instance_variable_get("@#{name}")
        else
          instance_variable_set("@#{name}", args.first)
        end
      end
    end
  end
end
