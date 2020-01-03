class Dynomite::Item
  module PrimaryKey
    extend ActiveSupport::Concern

    delegate :partition_key_field, :hash_key_field, :sort_key_field, :range_key_field,
             :primary_key_fields, :primary_key, :composite_key, :composite_key?,
             :attribute_definitions, :hash_key, :range_key, :key_schema,
             to: :class

    included do
      before_update :check_primary_key_changed!
    end

    def check_primary_key_changed!
      if primary_key_changed?
        changed_primary_keys = changed & primary_key_fields
        raise Dynomite::Error::PrimaryKeyChangedError, "Cannot change the primary key of an existing record: #{changed_primary_keys}"
      end
    end

    def partition_key
      send(partition_key_field) if partition_key_field
    end
    alias hash_key partition_key

    def sort_key
      send(sort_key_field) if sort_key_field
    end
    alias range_key sort_key

    # Example: {category: "books", sku: "302"}
    def primary_key
      primary_key = {}
      primary_key[partition_key_field.to_sym] = partition_key
      primary_key[sort_key_field.to_sym] = sort_key if sort_key_field
      primary_key
    end

    def primary_key_changed?
      !(changed & primary_key_fields).empty?
    end

    class_methods do
      extend Memoist

      def partition_key_field
        discover_schema_key("HASH") unless abstract?
      end
      alias hash_key_field partition_key_field

      def sort_key_field
        discover_schema_key("RANGE") unless abstract?
      end
      alias range_key_field sort_key_field

      def primary_key_fields
        composite_key? ? composite_key : [partition_key_field] # ensure Array to make interface consistent
      end

      def composite_key
        [partition_key_field, sort_key_field] if composite_key?
      end

      def composite_key?
        !!sort_key_field
      end

      def attribute_definitions
        table = desc_table(table_name)
        table.attribute_definitions
      end

      def key_schema
        table = desc_table(table_name)
        table.key_schema
      end

      def discover_schema_key(key_type)
        table = desc_table(table_name)
        table.key_schema.find { |a| a.key_type == key_type }&.attribute_name
      end
      memoize :discover_schema_key
    end
  end
end
