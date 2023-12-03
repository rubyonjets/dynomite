class Dynomite::Item
  module MagicFields
    extend ActiveSupport::Concern

    included do
      field :created_at, type: :time
      field :updated_at, type: :time
      before_save :set_created_at
      before_save :set_updated_at
      before_save :set_sort_key
      before_save :set_partition_key
    end

    def set_sort_key
      return unless sort_key_field
      return if @attrs[sort_key_field]
      @attrs.merge!(sort_key_field => generate_random_key_schema_value("RANGE")) # RANGE is the sort key
    end

    def set_partition_key
      return if @attrs[partition_key_field]
      if partition_key_field.to_s == "id"
        @attrs.merge!(partition_key_field => generate_id) # IE: post-0GKjo3Ck0OBL6nAi
      else
        @attrs.merge!(partition_key_field => generate_random_key_schema_value("HASH")) # HASH is the partition key
      end
    end

    def generate_random_key_schema_value(key_type)
      attribute_name = key_schema.find { |a| a.key_type == key_type }.attribute_name
      attribute_type = attribute_definitions.find { |a| a.attribute_name == attribute_name }.attribute_type
      case attribute_type
      when "N" # number
        # 40 digit number that does not start with 0
        first_digit = rand(1..9) # Generate a random digit from 1 to 9
        rest_of_digits = Array.new(39) { rand(0..9) }.join # Generate the remaining 39 digits
        random_number = "#{first_digit}#{rest_of_digits}"
        random_number.to_i
      when "S" # string
        # 40 character string
        Digest::SHA1.hexdigest([Time.now, rand].join) # IE: fead3c000892e9e8c78e821411bbaa9dc3cb938c
      end
    end

    def set_created_at
      self.created_at ||= Time.now
    end

    def set_updated_at
      self.updated_at = Time.now if changed?
    end

    class_methods do
      # Called in dynomite/engine.rb since need table name
      def discover_fields!
        return if abstract? # IE: ApplicationItem Dynomite::Item
        attribute_definitions.each do |attr|
          method_name = attr.attribute_name.to_sym
          field method_name unless public_method_defined?(method_name)
        end
      rescue Aws::DynamoDB::Errors::ResourceNotFoundException => e
        nil # Table does not exist yet
      end
    end
  end
end