class Dynomite::Item
  module Sti
    extend ActiveSupport::Concern

    included do
      class_attribute :inheritance_field_name
    end

    class_methods do
      def enable_sti(field_name='type')
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def self.inherited(subclass)
            field :#{field_name} # IE: field_name :type
            subclass.table_name(sti_base_table_name) # IE: subclass: Car base_table: vehicles
            subclass.inheritance_field_name = :#{field_name}

            before_save :set_type
            super
          end
        RUBY
      end
      alias inheritance_field enable_sti

      def sti_base_table_name
        klass = self
        table_name = nil
        until klass.abstract? # IE: ApplicationItem
          table_name = klass.name.pluralize.gsub('::','_').underscore # vehicles
          klass = klass.superclass
        end
        table_name
      end

      def sti_enabled?
        inheritance_field_name.present?
      end
    end

    def set_type
      self[self.class.inheritance_field_name] = self.class.name
    end
  end
end
