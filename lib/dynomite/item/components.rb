class Dynomite::Item
  module Components
    extend ActiveSupport::Concern

    included do
      extend Indexes
      extend Memoist
      extend TableNamespace

      include ActiveModel::Validations::Callbacks

      define_model_callbacks :initialize, :find, :touch, only: :after
      define_model_callbacks :save, :create, :update, :destroy

      include PrimaryKey
      include MagicFields # created_at, updated_at, partition_key (primary_key: id)
      include Id
    end

    include Dynomite::Client
    include Dsl
    include ActiveModel::Model
    include ActiveModel::Callbacks
    include ActiveModel::Dirty
    include ActiveModel::Serialization
    include WaiterMethods
    include Sti
    include Locking
    include Dynomite::Associations
    include Read
    include Write
  end
end
