module Dynomite
  module Associations
    module ManyAssociation
      include Association

      attr_accessor :query

      def initialize(*args)
        @query = {}
        super
      end

      include Enumerable

      # Delegate methods to the records the association represents.
      delegate :first, :last, :empty?, :size, :class, to: :records

      # @return the has many association. IE: user.posts
      def find_target
        return [] if source_ids.empty?

        # IE: user.posts - target class is Post
        if target_class.partition_key_field == "id" && target_class.sort_key_field.nil?
          # Quick find lookup
          Array(target_class.find(source_ids.to_a, raise_error: false))
        else
          relation.to_a
        end
      end

      def relation
        return [] if source_ids.empty? # check again in case user calls relation directly. IE: user.posts.relation
        # Slow scan lookup because of the in operator
        target_class.where("id.in": source_ids.to_a)
      end

      def records
        if query.empty?
          target
        else
          results_with_query(target)
        end
      end

      # Alias convenience methods for the associations.
      alias all records
      alias count size
      alias nil? empty?

      # Delegate include? to the records.
      def include?(item)
        records.include?(item)
      end

      # Add an item or array of items to an association.
      #
      #   tag.posts << post
      #   tag.posts << [post1, post2, post3]
      #
      # This preserves the current records in the association (if any) and adds
      # the item to the target association if it is detected to exist.
      #
      # It saves both models immediately - the source model and the target one
      # so any not saved changes will be saved as well.
      #
      # @param item [Dynomite::Item|Array] model (or array of models) to add to the association
      # @return [Dynomite::Item] the added model
      def <<(item)
        item = coerce_to_item(item)
        # normal relationship
        associate_one_way(item)

        # inverse relationship
        if target_association
          Array(item).each { |obj| obj.send(target_association).associate_one_way(source) }
        end

        item
      end
      alias associate <<

      def associate_one_way(item)
        items = Array(item)
        ids = items.collect { |o| coerce_to_id(o) }
        ids = source_ids.merge(ids)
        source.update_attribute_presence(source_attribute, ids)
      end

      # Removes an item or array of items from the association.
      #
      #   tag.posts.disassociate(post)
      #   tag.posts.disassociate(post1, post2, post3)
      #   tag.posts.disassociate([post1, post2, post3])
      #
      # This removes their records from the association field on the source,
      # and attempts to remove the source from the target association if it is
      # detected to exist.
      #
      # It saves both models immediately - the source model and the target one
      # so any not saved changes will be saved as well.
      #
      # @param item [Dynomite::Item|Array] model (or array of models) to remove from the association
      # @return [Dynomite::Item|Array] the deleted model
      def disassociate(*items)
        items.flatten!
        items.map! { |item| coerce_to_item(item) }
        # normal relationship
        items.each { |item| disassociate_one_way(item) }

        # inverse relationship
        if target_association
          items.each { |obj| obj.send(target_association).disassociate_one_way(source) }
        end
      end

      def disassociate_one_way(item)
        ids = source_ids - Array(coerce_to_id(item))
        source.update_attribute_presence(source_attribute, ids)
      end

      def disassociate_all
        # target is all items. IE: user.posts
        target.each do |item|
          disassociate(item)
        end
      end

      # Replace an association with item or array of items. This removes all of the existing associated records and replaces them with
      # the passed item(s), and associates the target association if it is detected to exist.
      #
      # @param [Dynomite::Item] item the item (or array of items) to add to the association
      #
      # @return [Dynomite::Item|Array] the added item
      def setter(item)
        target.each { |i| disassociate(i) }
        self << item
        item
      end

      # Create a new instance of the target class, persist it and add directly
      # to the association.
      #
      #   tag.posts.create!(title: 'foo')
      #
      # Several models can be created at once when an array of attributes
      # specified:
      #
      #   tag.posts.create!([{ title: 'foo' }, {title: 'bar'} ])
      #
      # If the creation fails an exception will be raised.
      #
      # @param attributes [Hash] attribute values for the new item
      # @return [Dynomite::Item|Array] the newly-created item
      def create!(attributes = {})
        self << target_class.create!(attributes)
      end

      # Create a new instance of the target class, persist it and add directly
      # to the association.
      #
      #   tag.posts.create(title: 'foo')
      #
      # Several models can be created at once when an array of attributes
      # specified:
      #
      #   tag.posts.create([{ title: 'foo' }, {title: 'bar'} ])
      #
      # @param attributes [Hash] attribute values for the new item
      # @return [Dynomite::Item|Array] the newly-created item
      def create(attributes = {})
        self << target_class.create(attributes)
      end

      # Create a new instance of the target class and add it directly to the association. If the create fails an exception will be raised.
      #
      # @return [Dynomite::Item] the newly-created item
      def each(&block)
        records.each(&block)
      end

      # Destroys all members of the association and removes them from the
      # association.
      #
      #   tag.posts.destroy_all
      #
      def destroy_all
        objs = target
        source.update_attribute_presence(source_attribute, nil)
        objs.each(&:destroy)
      end

      # Deletes all members of the association and removes them from the
      # association.
      #
      #   tag.posts.delete_all
      #
      def delete_all
        objs = target
        source.update_attribute_presence(source_attribute, nil)
        objs.each(&:delete)
      end

      def destroy_all
        objs = target
        source.update_attribute_presence(source_attribute, nil)
        objs.each(&:destroy)
      end

      # Naive association filtering.
      #
      #   tag.posts.where(title: 'foo')
      #
      # It loads lazily all the associated models and checks provided
      # conditions. That's why only equality conditions can be specified.
      #
      # @param args [Hash] A hash of attributes; each must match every returned item's attribute exactly.
      # @return [Dynomite::Association] the association this method was called on (for chaining purposes)
      def where(args)
        filtered = clone
        filtered.query = query.clone
        args.each { |k, v| filtered.query[k] = v }
        filtered
      end

      # Is this array equal to the association's records?
      #
      # @return [Boolean] true/false
      def ==(other)
        records == Array(other)
      end

      # Delegate methods we don't find directly to the records array.
      def method_missing(method, *args)
        if records.respond_to?(method)
          records.send(method, *args)
        else
          super
        end
      end

      private

      # If a query exists, filter all existing results based on that query.
      #
      # @param [Array] results the raw results for the association
      #
      # @return [Array] the filtered results for the query
      def results_with_query(results)
        results.find_all do |result|
          query.all? do |attribute, value|
            result.send(attribute) == value
          end
        end
      end
    end
  end
end
