# frozen_string_literal: true

require 'rails/generators'

# Note: Currently have to use the Rails namespace to allow the Rails generator lookup to work.
# Would like to figure how to use Dynomite as the namespace instead
# Usage:
#   jets generate application_item
module Rails
  module Generators
    class ApplicationItemGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      # FIXME: Change this file to a symlink once RubyGems 2.5.0 is required.
      def create_application_item
        template "application_item.rb", application_item_file_name
      end

      private
        def application_item_file_name
          @application_item_file_name ||=
            if namespaced?
              "app/models/#{namespaced_path}/application_item.rb"
            else
              "app/models/application_item.rb"
            end
        end
    end
  end
end
