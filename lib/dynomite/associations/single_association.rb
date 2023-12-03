module Dynomite
  module Associations
    module SingleAssociation
      include Association

      # target field name. IE: posts.user_id
      def declaration_field_name
        options[:foreign_key] || "#{name}_id"
      end

      def reader_target
        target
      end

      def setter(item)
        if item.nil?
          disassociate
        else
          associate(item)
        end
      end

      def associate(item)
        item = coerce_to_item(item)
        associate_one_way(item)

        # inverse relationship
        should_reload = false
        Array(target).each do |target_entry|
          if target_entry && target_association
            target_entry.send(target_association).associate_one_way(source)
            should_reload = true
          end
        end
        target.reload if should_reload

        self.target = item
      end

      def associate_one_way(item)
        # normal relationship
        source.update_attribute_presence(source_attribute, coerce_to_id(item))
      end

      def disassociate(_ = nil)
        # inverse relationship: user.posts removal. run first before target is nil
        should_reload = false
        Array(target).each do |target_entry|
          if target_entry && target_association
            target_entry.send(target_association).disassociate_one_way(source)
            should_reload = true
          end
        end
        target.reload if should_reload

        # normal relationship: post.user removal
        disassociate_one_way

        self.target = nil
      end

      # Delete a model from the association.
      #
      #   post.logo.disassociate # => nil
      #
      # Saves both models immediately - a source model and a target one so any
      # unsaved changes will be saved. Doesn't delete an associated model from
      # DynamoDB.
      #
      #   _ = nil so can keep the same interface for removing has_many_and_belongs_to associations
      #
      def disassociate_one_way(_ = nil)
        # normal relationship: post.user removal
        source.update_attribute_presence(source_attribute, nil)
      end

      # Create a new instance of the target class, persist it and associate.
      #
      #   post.logo.create!(hight: 50, width: 90)
      #
      # If the creation fails an exception will be raised.
      #
      # @param attributes [Hash] attributes of a model to create
      # @return [Dynomite::Item] created model
      def create!(attributes = {})
        setter(target_class.create!(attributes))
      end

      # Create a new instance of the target class, persist it and associate.
      #
      #   post.logo.create(hight: 50, width: 90)
      #
      # @param attributes [Hash] attributes of a model to create
      # @return [Dynomite::Item] created model
      def create(attributes = {})
        setter(target_class.create(attributes))
      end

      # Is this item equal to the association's target?
      #
      # @return [Boolean] true/false
      def ==(other)
        target == other
      end

      if ::RUBY_VERSION < '2.7'
        # Delegate methods we don't find directly to the target.
        def method_missing(method, *args, &block)
          if target.respond_to?(method)
            target.send(method, *args, &block)
          else
            super
          end
        end
      else
        # Delegate methods we don't find directly to the target.
        def method_missing(method, *args, **kwargs, &block)
          if target.respond_to?(method)
            target.send(method, *args, **kwargs, &block)
          else
            super
          end
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        target.respond_to?(method_name, include_private) || super
      end

      def nil?
        target.nil?
      end

      def empty?
        # This is needed to that ActiveSupport's #blank? and #present?
        # methods work as expected for SingleAssociations.
        target.nil?
      end

      private

      # Find the target of the has_one association.
      #
      # @return [Dynomite::Item] the found target (or nil if nothing)
      def find_target
        return if source_ids.empty?

        target_class.find(source_ids.first, raise_error: false)
      end

      def target=(item)
        @target = item
        @loaded = true
      end
    end
  end
end
