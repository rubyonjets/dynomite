require "dynomite"

module Jets::Command
  class Dynamodb < Base
    desc "migrate", "Runs migrations"
    long_desc Help.text('dynamodb:migrate')
    def migrate
      Jets.boot
      Dynomite::Migration::Runner.new(options).run
    end

    desc "generate NAME", "Creates a migration for a DynamoDB table"
    long_desc Help.text('dynamodb:generate')
    option :action, desc: "create_table, update_table, delete_table. Defaults to convention based on the name of the migration."
    option :partition_key, default: "id", desc: "table's partition key"
    option :sort_key, default: nil, desc: "table's sort key"
    option :table_name, desc: "override the the conventional table name"
    def generate(name)
      Dynomite::Migration::Generator.new(name, options).generate
    end

    desc "seed", "Seed data"
    long_desc Help.text('dynamodb:seed')
    def seed
      Jets.boot
      Dynomite::Seed.new(options).run
    end
  end
end
