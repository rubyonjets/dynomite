class Dynomite::Migration::Dsl
  module Index
    def add_gsi(attrs={})
      attrs = normalize_index_attrs(attrs, :partition_key)
      @gsi_indexes << Gsi.new(:create, attrs) # store in @gsi_indexes for the parent Dsl to use
    end
    alias create_gsi add_gsi

    def update_gsi(attrs={})
      attrs = normalize_index_attrs(attrs, :partition_key)
      @gsi_indexes << Gsi.new(:update, attrs) # store in @gsi_indexes for the parent Dsl to use
    end

    def remove_gsi(attrs={})
      attrs = normalize_index_attrs(attrs, :partition_key)
      @gsi_indexes << Gsi.new(:delete, attrs) # store in @gsi_indexes for the parent Dsl to use
    end
    alias delete_gsi remove_gsi

    def add_lsi(attrs={})
      # dont need create with lsi indexes, they are created as part of create_table
      partition_key_name = @partition_key_identifier.split(':').first
      attrs = normalize_index_attrs(attrs, :sort_key)
      @lsi_indexes << Lsi.new(partition_key_name, attrs) # store in @lsi_indexes for the parent Dsl to use
    end
    alias create_lsi add_lsi

    def normalize_index_attrs(attrs, type=:partition_key)
      if attrs.is_a?(String) || attrs.is_a?(Symbol)
        {type => attrs.to_s}
      else
        attrs
      end
    end

    # maps each lsi to the hash structure expected by dynamodb update_table
    # under the lsi_secondary_index_creates key:
    #
    #   { create: {...} }
    #   { update: {...} }
    #   { delete: {...} }
    def lsi_secondary_index_creates
      @lsi_indexes.map do |lsi|
        lsi.params
      end
    end

    # maps each lsi to the hash structure expected by dynamodb update_table
    # under the gsi_secondary_index_creates key:
    #
    #   { create: {...} }
    #   { update: {...} }
    #   { delete: {...} }
    def gsi_secondary_index_creates
      @gsi_indexes.map do |gsi|
        gsi.params
      end
    end

    # maps each gsi to the hash structure expected by dynamodb update_table
    # under the global_secondary_index_updates key:
    #
    #   { create: {...} }
    #   { update: {...} }
    #   { delete: {...} }
    def global_secondary_index_updates
      @gsi_indexes.map do |gsi|
        { gsi.action => gsi.params }
      end
    end
  end
end
