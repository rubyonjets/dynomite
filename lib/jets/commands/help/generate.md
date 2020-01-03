## Examples

    jets dynamodb:generate create_products --partition-key category --sort-key product_id:number
    jets dynamodb:generate create_comments --partition-key post_id:string --sort-key created_at:string
    jets dynamodb:generate create_posts    --partition-key id        # default attribute type is string
    jets dynamodb:generate create_posts    --partition-key id:number # attribute type will be number

## Running migrations

    $ jets dynamodb:migrate

To add global secondary indexes:

    $ jets dynamodb:generate update_comments --partition-key user_id:string --sort-key created_at:string

To run:

    $ jets dynamodb:migrate

## Conventions

A create_table or update_table migration file is generated based name you provide.  If `update` is included in the name then an update_table migration table is generated. If `create` is included in the name then a create_table migration table is generated.

The table_name is also inferred from the migration name you provide.  Examples:

    $ jets dynamodb:generate create_posts    # table_name: posts
    $ jets dynamodb:generate update_comments # table_name: comments

You can override both of these conventions:

    $ jets dynamodb:generate create_my_posts --table-name posts
    $ jets dynamodb:generate my_posts --action create_table --table-name posts
    $ jets dynamodb:generate my_posts --action update_table --table-name posts
