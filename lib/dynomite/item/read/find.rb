module Dynomite::Item::Read
  module Find
    extend ActiveSupport::Concern

    # Note: options are merged into get_item params.
    def find(id, options={})
      self.class.find(id, options)
    end

    class_methods do
      def find_by(attrs, options={})
        # Note: ActionController::Parameters does not have .any? Unsure if should use .to_h on it
        # A blank attrs will break find_by since DynamoDB doesnt support blank attribute values
        # Guard blank attrs like and return new return so validation error surfaces in a standard CRUD scaffold
        attrs = attrs.to_h
        return nil if attrs.any? { |k,v| v.blank? }

        primary_key_attrs = attrs.stringify_keys.slice(partition_key_field, sort_key_field).symbolize_keys
        if primary_key_attrs.size == primary_key_fields.size
          find(primary_key_attrs, options.merge(raise_error: false))
        else
          where(attrs).first # possible scan
        end
      end

      # Examples with out the args are received.
      #
      #   Post.find("ae3ae")
      #     args ["ae3ae"]
      #   Post.find(id: "ae3ae")
      #     args [{:id=>"ae3ae"}]
      #   Post.find("ae3ae", consistent_read: true)
      #     args ["ae3ae", {:consistent_read=>true}]
      #   Post.find({id: "ae3ae"}, consistent_read: true)
      #     args [{:id=>"ae3ae"}, {:consistent_read=>true}]
      #   Product.find(category: "Electronics", product_id: 101)
      #     args [{:category=>"Electronics", :product_id=>101}]
      #   Product.find({category: "Electronics", product_id: 101}, consistent_read: true)
      #     args [{:category=>"Electronics", :product_id=>101}, {:consistent_read=>true}]
      #
      #   Product.find(id1,id2,id3)
      #     args [id1,id2,id3]
      #   Product.find([id1,id2,id3])
      #     args [[id1,id2,id3]]
      #   Product.find([id1,id2,id3], consistent_read: true)
      #     args [[id1,id2,id3], {:consistent_read=>true}]
      #
      # Note: options are merged into get_item params.
      def find(*args)
        options = {}
        key_schema = if args.size == 1
                       # args is an array of one element:
                       # ["f74de472"]
                       # [{:id=>"f74de472"}]
                       # [{:category=>"Electronics", :product_id=>101}]
                       # [[id1, id2, id3]]
                       get_key_schema_from_one_arg(args.first)
                     else
                       # ["f74de472", {:consistent_read=>true}]
                       # [{:id=>"f74de472"}, {:consistent_read=>true}]
                       # [{:category=>"Electronics", :product_id=>101}, {:consistent_read=>true}]
                       # [[id1, id2, id3], {:consistent_read=>true}] # HERE
                       options = args.extract_options!
                       if args.size >= 2 # still at least 2 after extracting options
                         get_key_schema_from_one_arg(args) # [id1, id2, id3]
                       else
                         get_key_schema_from_one_arg(args.first)
                       end
                     end

        raise_error = options.delete(:raise_error) # clean for params
        raise_error = raise_error.nil? ? true : raise_error

        # Early return if ids the provided arg. find(ids)
        # List of ids: IE: [id1, id2, id3]
        if key_schema.is_a?(Array)
          keys = key_schema # [{"id"=>"post-1"}, {"id"=>"post-2"}]
          ids = keys.map(&:values).flatten # ["post-1", "post-2"]
          items = batch_get_items(keys, options)
          result = items
          result = nil if items.size != keys.size # some missing items

          if result.nil?
            if raise_error
              looking, found = ids, items.map(&:id)
              missing = ids - found
              message = "Couldn't find all #{self.name.pluralize} with '#{partition_key_field}': (#{looking.join(', ')}) (found #{found.size} results, but was looking for #{looking.size})"
              message << ". Missing: #{missing.sort.join(', ')}" if found.size > 0
              raise Dynomite::Error::RecordNotFound.new(message)
            else
              return items # return early
            end
          else
            return items
          end
        end

        params = {
          table_name: table_name,
          key: key_schema,
        }
        params.merge!(options)

        log_debug(params)
        attrs = client.get_item(params).item # unwraps the item's attrs

        # Mimic ActiveRecord::RecordNotFound behavior
        raise Dynomite::Error::RecordNotFound if attrs.nil? && raise_error != false

        build_item(attrs)
      end

      def batch_get_items(*args)
        options = args.extract_options!
        retries = options.delete(:retries)|| 0
        keys = args.flatten
        items = []
        unprocessed_keys = []

        # exponential backoff to handle unprocessed keys
        delay = 2 ** retries
        if retries > 0
          logger.debug "batch_get_items: sleeping for #{delay} seconds and will retry. retries: #{retries}"
          sleep(delay)
          if retries >= 3 # 2 + 4 + 8 = 14s total of retries
            raise "ERROR: Exceeded max retries: #{retries}. Unable to batch_get_items for keys: #{keys.inspect}"
          end
        end

        max_batch_size = 100
        keys.each_slice(max_batch_size).each do |slice|
          # Note: client.batch_get_items will silently not return items if any of the
          # keys are not found. So we do not have to do a compact and remove nils.
          # Merge options to allow passing in consistent_read: true
          params = options.merge(keys: slice)
          resp = client.batch_get_item(
            request_items: {
              table_name => params
            }
          )
          resp[:responses][table_name].each do |item|
            items << build_item(item)
          end
          unprocessed_keys += resp[:unprocessed_keys][table_name] if resp[:unprocessed_keys][table_name]
        end

        # Recursively call batch_get_items if there are unprocessed_keys
        # Increase the retries by 1 for exponential backoff
        items += batch_get_items(unprocessed_keys, options.merge(retries: retries+1)) if unprocessed_keys.any?

        items
      end

      def build_item(attrs)
        return unless attrs # is nil when no item found: client.get_item(params).item
        item = self.new(attrs)
        item.new_record = false
        item.run_callbacks :find # find and find_by leads to build_item. so we can run callbacks here
        item
      end

      # Examples of id:
      #
      #   "f74de472"
      #   {:id=>"f74de472"}
      #   {:category=>"Electronics", :product_id=>101}
      #   [id1, id2, id3]
      #
      # Returns hash of key_schema
      #
      #   { id: "f74de472" }
      #   { category: "Electronics", product_id: 101 }
      #
      def get_key_schema_from_one_arg(id)
        # standardize key structure
        case id
        when Integer, String, Symbol # "f74de472"
          if id.is_a?(String) && id.starts_with?(id_prefix)
            { id: id }
          else
            if sort_key_field
              raise "ERROR: You must provide both partition and sort key for class: #{self.name} partition_key_field: #{partition_key_field} sort_key_field: #{sort_key_field}"
            end
            { partition_key_field => id }
          end
        when Hash  # {:id=>"f74de472"} or {:category=>"Electronics", :product_id=>101}
          id # User needs to provide both partition and sort key
        when Array # [id1, id2, id3]
          id.map do |i|
            i.is_a?(Hash) ? i : { partition_key_field => i }
          end
        end
      end
    end
  end
end
