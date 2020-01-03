class Dynomite::Item
  module Write
    extend ActiveSupport::Concern

    # Not using method_missing to allow usage of dot notation and assign
    # @attrs because it might hide actual missing methods errors.
    # DynamoDB attrs can go many levels deep so it makes less make sense to
    # use to dot notation.

    def save(options={})
      options.reverse_merge!(validate: true)
      return self if options[:validate] && !valid?

      action = new_record? ? :create : :update
      run_callbacks(:save) do
        run_callbacks(action) do
          if action == :create
            PutItem.call(self, options)
          else # :update
            call_update_strategy(options)
          end
        end
      end
    end

    # Similar to save, but raises an error on failed validation.
    def save!(options={})
      raise_error_if_invalid
      save(options)
    end

    # post.update(title: "test", body: "body")
    # post.update({title: "test", body: "body"}, {validate: false})
    def update(attrs={}, options={})
      self.attrs.merge!(attrs)
      options.reverse_merge!(validate: true)
      return false if options[:validate] && !valid?

      run_callbacks(:save) do
        run_callbacks(:update) do
          call_update_strategy(options)
        end
      end
    end

    def call_update_strategy(options)
      if Dynomite.config.update_strategy == :update_item
        # Note: fields assigned directly with brackets are not tracked as changed
        # IE: post[:title] = "test"
        UpdateItem.call(self, options)
      else # default
        PutItem.call(self, options)
      end
    end

    # Similar to update, but raises an error on failed validation.
    def update!(attrs={}, options={})
      raise_error_if_invalid
      update(attrs, options)
    end

    # When you add an item, the primary key attributes are the only required attributes.
    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#put_item-instance_method
    def put(options={})
      found_primary_keys = self.attrs.keys.map(&:to_s) & primary_key_fields
      unless primary_key_fields.sort == found_primary_keys
        raise Dynomite::Error::InvalidPut.new("Invalid put. The primary key fields #{primary_key_fields} must be present in the attrs #{attrs}")
      end

      options.reverse_merge!(validate: true)
      return self if options[:validate] && !valid? # return self so can grab errors in invalid. save does the same thing

      # Run callbacks for put so id is also set
      run_callbacks(:save) do
        run_callbacks(:update) do
          PutItem.call(self, options.merge(put: true))
        end
      end
    end
    alias replace put

    def put!(options={})
      raise_error_if_invalid
      put(options)
    end
    alias replace! put!

    def destroy(options={})
      run_callbacks(:destroy) do
        DeleteItem.call(self, options)
      end
    end

    def delete(options={})
      DeleteItem.call(self, options)
    end

    attr_reader :_touching
    def touch(*names, **options)
      if new_record?
        raise Dynomite::Error, 'cannot touch on a new item'
      end

      time_to_assign = options.delete(:time) || Time.now

      self.updated_at = time_to_assign
      names.each do |name|
        attrs.send("#{name}=", time_to_assign)
      end

      @_touching = true
      run_callbacks :touch do
        UpdateItem.call(self, options)
      end

      self
    end

    # Examples:
    #   user.increment(:likes)
    #   user.increment(:likes, 2)
    def increment(attribute, by = 1)
      self[attribute] ||= 0
      self[attribute] += by
      self
    end

    # Increment counter. Validations and callbacks are skipped.
    #
    # Examples:
    #
    #   user.increment!(:likes)
    #   user.increment!(:likes, 2)
    #   user.increment!(:likes, touch: true)
    #   user.increment!(:likes, touch: :created_at)
    #   user.increment!(:likes, touch: [:viewed_at, :created_at])
    #
    def increment!(attribute, by = 1, touch: nil)
      increment(attribute, by)

      now = Time.now
      attrs = Array(touch).inject({}) do |attrs, field|
        attrs.merge!(field => now)
      end if touch

      run_callbacks :touch do
        UpdateItem.new(self).save_changes(attrs: attrs, count_changes: { attribute => by })
      end

      self
    end

    # Example:
    #
    #   user = User.first
    #   user.banned? # => false
    #   user.toggle(:banned)
    #   user.banned? # => true
    #
    def toggle(attribute)
      self[attribute] = !public_send("#{attribute}?")
      self
    end

    def toggle!(attribute)
      toggle(attribute).update_attribute(attribute, self[attribute])
    end

    def raise_error_if_invalid
      raise Dynomite::Error::Validation, "Validation failed: #{errors.full_messages.join(', ')}" unless valid?
    end

    class_methods do
      def put(attrs={}, &block)
        new(attrs, &block).put
      end

      def put!(attrs={}, &block)
        new(attrs, &block).put!
      end

      def create(attrs={}, &block)
        new(attrs, &block).save
      end
      alias create_with create

      def create!(attrs={}, &block)
        new(attrs, &block).save!
      end

      def find_or_create_by(attrs={})
        find_by(attrs) || create(attrs)
      end

      def find_or_create_by!(attrs={})
        find_by(attrs) || create!(attrs)
      end

      def find_or_initialize_by(attrs)
        find_by(attrs) || new(attrs)
      end
    end
  end
end
