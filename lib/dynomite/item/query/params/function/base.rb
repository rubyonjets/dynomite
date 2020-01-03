module Dynomite::Item::Query::Params::Function
  class Base
    include Dynomite::Item::Query::Params::Helpers
    include Dynomite::Types

    def initialize(query)
      @query = query
    end

    def build_attribute_names_with_dot_paths(paths)
      attribute_names = {}
      paths.each do |path|
        fields = path.split('.')
        fields.each do |field|
          if field.starts_with?('#')
            key = field
            value = field[1..-1]
          else
            key = "##{field}"
            value = field
          end
          attribute_names[key] = value
        end
      end
      attribute_names
    end

    def attribute_values
      {}
    end
  end
end

