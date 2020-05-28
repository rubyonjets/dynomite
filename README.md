# Dynomite

[![BoltOps Badge](https://img.boltops.com/boltops/badges/boltops-badge.png)](https://www.boltops.com)

NOTE: Am looking for maintainers to help with this gem. Send me an email!

IMPORTANT: The next major version of Dynomite will be ActiveModel compatible. A POC is in the [edge](https://github.com/tongueroo/dynomite/tree/edge) branch. It's still very rough and experimental. Would not recommend using it yet, but wanted to note it.

A simple wrapper library to make DynamoDB usage a little more friendly.  The modeling is ActiveRecord-ish but not exactly because DynamoDB is a different type of database.  Examples below explain it best:

## Jets Docs

* [Database DynamoDB](https://rubyonjets.com/docs/database/dynamodb/)

## Examples

First define a class:

```ruby
class Post < Dynomite::Item
  # partition_key "id" # optional, defaults to id

  column :id, :title, :desc
end
```

### Create

```ruby
post = Post.new
post = post.replace(title: "test title")
post.attrs # {"id" => "generated-id", title" => "test title"}
```

`post.attrs[:id]` now contain a generated unique partition_key id.  Usually the partition_key is 'id'. You can set your own unique id also by specifying id.

```ruby
post = Post.new(id: "myid", title: "my title")
post.replace
post.attrs # {"id" => "myid", title" => "my title"}
```

Note that the replace method replaces the entire item, so you need to merge the attributes if you want to keep the other attributes.  Know this is weird, but this is how DynamoDB works.

### Find

```ruby
post = Post.find("myid")
post.attrs = post.attrs.deep_merge("desc": "my desc") # keeps title field
post.replace
post.attrs # {"id" => "myid", title" => "my title", desc: "my desc"}
```

The convenience `attrs` method performs a deep_merge:

```ruby
post = Post.find("myid")
post.attrs("desc": "my desc 2") # <= does a deep_merge
post.replace
post.attrs # {"id" => "myid", title" => "my title", desc: "my desc 2"}
```

Note, a race condition edge case can exist when several concurrent replace
calls are happening.  This is why the interface is called replace to
emphasize that possibility.

### Delete

```ruby
resp = Post.delete("myid")  # dynamodb client resp
# or
post = Post.find("myid")
resp = post.delete  # dynamodb client resp
```

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

### Where

The where could be prettied up. Appreciate any pull requests.

```ruby
Post.where({category: "Drama"}, {index_name: "category-index"})
```

Examples are also in [item_spec.rb](spec/lib/dynomite/item_spec.rb).

## Column Lists

You can define your column list using the `column` method inside your item class. This gives you
a possibility to access your column fields using getters and setters. Also, any predefined column
can be passed to `ActiveModel::Validations` (see Validations).

```ruby
class Post < Dynomite::Item
  column :id, :name
end

post = Post.new
post.name = "My First Post"
post.replace

puts post.id # 1962DE7D852298C5CDC809C0FEF50D8262CEDF09
puts post.name # "My First Post"
```

Note that any column not defined using the `column` method can still be accessed using the `attrs`
method.

## Validations

You can add validations known from ActiveRecord to your Dynomite items.
Just add `include ActiveModel::Validations` at the top of your item class.

```ruby
class Post < Dynomite::Item
  include ActiveModel::Validations

  column :id, :name # needed

  validates :id, presence: true
  validates :name, presence: true
end
```

**Be sure to define all validated columns using `column` method**.

Validations are executed by default as soon as you call the `replace` method, returning `false` on
failure. It also can be ran manually using the `valid?` method just like with ActiveRecord models.


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

### TODO

* improve Post.where.  Something like `Post.index_name("user_id").where(category_name: "Entertainment")` would be nice.
* implement `post.update` with `db.update_item` in a Ruby-ish way
