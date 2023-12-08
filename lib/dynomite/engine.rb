module Dynomite
  class Engine < ::Jets::Engine
    config.after_initialize do
      Dynomite.config.default_namespace = Jets.project_namespace # IE: demo-dev
      Dynomite.config.migration.deletion_protection_enabled = Jets.env.production?

      # Discover all the fields for all the models from attribute_definitions
      # and create field methods. Has to be done after_initialize because
      # need model names for the table_name.
      Dynomite::Item.descendants.each do |klass|
        klass.discover_fields!
      end if Dynomite.config.discover_fields
    end
  end
end
