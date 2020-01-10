# Dynomite

[![BoltOps Badge](https://img.boltops.com/boltops/badges/boltops-badge.png)](https://www.boltops.com)

A DynamoDB ORM that is ActiveModel compatible.

NOTE: Looking for maintainers for this gem. Send an email!

**IMPORTANT**: This edge branch is highly experimental and unfinished.

## Jets Docs

* [Database DynamoDB](https://rubyonjets.com/docs/database/dynamodb/)

## Examples

First, define a class:

```ruby
class Post < Dynomite::Item
  field :id, :title, :desc
end
```

### Create

```ruby
post = Post.new(title: "test title")
post.save
post.id  # generated IE: 2db602210009613583b25240b0b4e3cd3fc4fe9f
```

`post.id` now contains a generated value.  `post.id` is the DynamoDB partition_key used for fast lookups like `Post.find`

### Find

```ruby
post = Post.find("2db602210009613583b25240b0b4e3cd3fc4fe9f")
post.title # => "test title"
```

### Destroy

```ruby
post = Post.find("myid")  # dynamodb client resp
post.destroy
```

### Where

Chained where query builder.

```ruby
posts = Post.where(title: "test post", category: "Drama").where(desc: "test desc")
posts.each { |p| puts p }
```

The query builder discovers indexes automatically. When indexes are available, dynomite will use the faster [DynamoDB query](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#query-instance_method) method. When indexes are not available, dynomite falls back to the slower [DynamoDB scan](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#scan-instance_method).

You can override the auto-discovered index with the index method:

```ruby
posts = Post.where(title: "test post").index("my-index")
posts.each { |p| puts p }
```

## Low-Level Methods

The `scan` and `query` are low-level methods that correspond to the raw DynamoDB Client methods. They automatically:

* add the `table_name` to the params
* return model items instances like `Post` instead of the raw resp.table.items

### Scan

```ruby
options = {}
posts = Post.scan(options)
posts # Array of Post items.  [Post.new, Post.new, ...]
```

### Query

```ruby
posts = Post.query(
  index_name: 'category-index',
  expression_attribute_names: { "#category_name" => "category" },
  expression_attribute_values: { ":category_value" => "Entertainment" },
  key_condition_expression: "#category_name = :category_value",
)
posts # Array of Post items.  [Post.new, Post.new, ...]
```

## Field Definitions

Define fields using the `field` method inside your item class.

```ruby
class Post < Dynomite::Item
  field :name
end

post = Post.new
post.name = "My First Post"
post.save

puts post.id # 1962DE7D852298C5CDC809C0FEF50D8262CEDF09
puts post.name # "My First Post"
```

Note that any field not defined using the `field` method can still be accessed using the `attrs` method.

```ruby
post = Post.new
post.attrs = {name: "My First Post"}
post.attrs
```

### Magic Fields

You get these fields for free: id, created_at, updated_at.

Field | Description
--- | ---
id | The partition_key. Defaults to the name `id` and can be changed. IE: `partition_key :myid`
created_at | Automatically initially set when items are created.
updated_at | Automatically set when new items are updated.

## Validations

You can add validations to declared fields.

```ruby
class Post < Dynomite::Item
  field :name
  validates :name, presence: true
end
```

**Be sure to define all validated fields using `field` method**.

Validations can also be ran manually using the `valid?` method, just like with ActiveRecord models.

## Callbacks

These callbacks are supported: create, save, destroy, initialize, update. Example:

```ruby
class Post < Dynomite::Item
  field :name
  before_save :set_name
  def set_name
    self.name = "my name"
  end
end
```

## Migration Support

Dynomite supports ActiveRecord-like migrations.  Here's a short example:

```ruby
class CreateCommentsMigration < Dynomite::Migration
  def up
    create_table :comments do |t|
      t.partition_key "post_id:string" # required
      t.sort_key  "created_at:string" # optional
      t.billing_mode "PAY_PER_REQUEST"
    end
  end
end
```

More examples are in the [docs/migrations](docs/migrations) folder.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dynomite'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dynomite

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tongueroo/dynomite.
