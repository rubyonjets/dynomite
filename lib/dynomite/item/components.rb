class Dynomite::Item
  module Components
    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Callbacks
      extend Dsl
      extend Indexes
      extend Memoist

      define_model_callbacks :create, :save, :destroy, :initialize, :update

      include MagicFields
      before_save :set_partition_id
      before_save :set_created_at
      before_save :set_updated_at
    end

    include ActiveModel::Model
    include Dynomite::Client
    include Dynomite::Errors
    include Query
    include TableNamespace
    include WaiterMethods
  end
end
