class Dynomite::Item
  module MagicFields
    extend ActiveSupport::Concern

    included do
      field partition_key, :created_at, :updated_at
    end

    def set_partition_id
      @attrs.merge!(
        partition_key => Digest::SHA1.hexdigest([Time.now, rand].join)
      ) unless @attrs[partition_key]
    end

    def set_created_at
      self.created_at ||= Time.now
    end

    def set_updated_at
      self.updated_at = Time.now
    end
  end
end