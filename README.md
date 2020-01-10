# Dynomite

[![BoltOps Badge](https://img.boltops.com/boltops/badges/boltops-badge.png)](https://www.boltops.com)

A DynamoDB ORM that is ActiveModel compatible.

NOTE: Am looking for maintainers to help with this gem. Send me an email!

## Jets Docs

* [Database DynamoDB](https://rubyonjets.com/docs/database/dynamodb/)

## Examples

First define a class:

```ruby
class Post < Dynomite::Item
  # partition_key "id" # optional, defaults to id

  field :id, :title, :desc
end
```

### Create

```ruby
post = Post.new(title: "test title")
post.save
post.id  # generated IE: 2db602210009613583b25240b0b4e3cd3fc4fe9f
```

`post.id` now contain a generated value.  `post.id` is the DynamoDB partition_key used for simple lookups like `Post.find`

### Find

```ruby
post = Post.find("2db602210009613583b25240b0b4e3cd3fc4fe9f")
post.title # => "test title"
```

### Delete

```ruby
resp = Post.delete("myid")  # dynamodb client resp
# or
post = Post.find("myid")
resp = post.delete  # dynamodb client resp
```

### Where

The where could be prettied up. Appreciate any pull requests.

```ruby
Post.where({category: "Drama"}, {index_name: "category-index"})
```

Examples are also in [item_spec.rb](spec/lib/dynomite/item_spec.rb).

## Low-Level Methods

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

You can define your fields using the `field` method inside your item class. This gives you a possibility to access your fields using getters and setters.

```ruby
class Post < Dynomite::Item
  column :name
end

post = Post.new
post.name = "My First Post"
post.save

puts post.id # 1962DE7D852298C5CDC809C0FEF50D8262CEDF09
puts post.name # "My First Post"
```

Note that any column not defined using the `column` method can still be accessed using the `attrs`
method.

### Magic Fields

These fields are automatically created: id, created_at, updated_at.

Field | Description
--- | ---
id | The partition_key. Defaults to the name `id` and can be changed. IE: `partition_key :myid`
created_at | Automatically iniitally set when new items are created.
updated_at | Automatically set when new items are updated.

## Validations

You can add validations to declared fields.

```ruby
class Post < Dynomite::Item
  column :name
  validates :name, presence: true
end
```

**Be sure to define all validated columns using `field` method**.

Validations can als be ran manually using the `valid?` method just like with ActiveRecord models.

## Migration Support

Dynomite supports ActiveRecord-like migrations.  Here's a short example:

```ruby
class CreateCommentsMigration < Dynomite::Migration
  def up
    create_table :comments do |t|
      t.partition_key "post_id:string" # required
      t.sort_key  "created_at:string" # optional
      t.provisioned_throughput(5) # sets both read and write, defaults to 5 when not set
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
