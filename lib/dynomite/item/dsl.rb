require "dynomite/reserved_words"

class Dynomite::Item
  module Dsl
    extend ActiveSupport::Concern

    class_methods do
      # Defines column. Defined column can be accessed by getter and setter methods of the same
      # name (e.g. [model.my_column]). Attributes with undefined columns can be accessed by
      # [model.attrs] method.
      def fields(*names)
        if names.empty? # getter
          fields_meta # meta info for all fields
        else # setter
          names.each(&method(:add_field))
        end
      end
      alias_method :columns, :fields

      # @see Item.column
      def add_field(name, options={})
        name = name.to_sym
        return if self.field_names.include?(name)
        self.fields_map[name] = options # store original options for reference for fields_meta

        if Dynomite::RESERVED_WORDS.include?(name.to_s)
          raise Dynomite::Error::ReservedWord, "'#{name}' is a reserved word"
        end

        # https://guides.rubyonrails.org/active_model_basics.html#dirty
        # Dirty support. IE: changed? and changed_attributes
        # Requires us to define the attribute method this way
        define_attribute_methods name # for dirty support

        define_method(name) do
          @attrs ||= {}
          value = @attrs[name]
          typecaster = Typecaster.new(self)
          type = options[:type] || Dynomite.config.default_field_type
          typecaster.cast_to_type(type, value)
        end

        define_method("#{name}=") do |value|
          @attrs ||= {}

          typecaster = Typecaster.new(self)
          type = options[:type] || Dynomite.config.default_field_type
          value_casted = typecaster.cast_to_type(type, value, on: :write)
          old_value = read_attribute(name)
          old_value = typecaster.cast_to_type(type, old_value, on: :write)

          send "#{name}_will_change!" if old_value != value_casted # from define_attribute_methods *names
          @attrs[name] = value_casted
        end

        define_method("#{name}?") do
          !!send(name)
        end if options[:type] == :boolean

        if default = options[:default]
          method_name = "set_#{name}_default".to_sym
          define_method(method_name) do
            return unless read_attribute(name).nil?
            value = case default
                    when Symbol
                      send(default)
                    when Proc
                      default.call
                    else
                      default
                    end
            send("#{name}=", value)
          end
          before_save method_name
        end
      end
      alias_method :field, :add_field
      alias_method :column, :add_field

      def field_names
        klass, field_names = self, []
        while klass.respond_to?(:fields_map)
          current_field_names = klass.fields_map.keys || []
          field_names += current_field_names
          klass = klass.superclass
        end
        field_names.sort
      end
      alias_method :column_names, :field_names

      def fields_meta
        klass, fields_meta = self, {}
        while klass.respond_to?(:fields_map)
          fields_meta.merge!(klass.fields_map)
          klass = klass.superclass
        end
        fields_meta
      end
    end
  end
end
