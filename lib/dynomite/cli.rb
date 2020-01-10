module Dynomite
  class CLI < Command
    desc "migrate", "Run migrations"
    long_desc Help.text(:migrate)
    def migrate
      Migration::Runner.new(options).run
    end

    desc "generate [name]", "Creates a migration for a DynamoDB table"
    long_desc Help.text('generate')
    option :action, desc: "create_table or update_table. Defaults to convention based on the name of the migration."
    option :partition_key, default: "id:string", desc: "table's partition key"
    option :sort_key, default: nil, desc: "table's sort key"
    option :table_name, desc: "override the the conventional table name"
    def generate(name)
      Migration::Generator.new(name, options).generate
    end

    desc "completion *PARAMS", "Prints words for auto-completion."
    long_desc Help.text(:completion)
    def completion(*params)
      Completer.new(CLI, *params).run
    end

    desc "completion_script", "Generates a script that can be eval to setup auto-completion."
    long_desc Help.text(:completion_script)
    def completion_script
      Completer::Script.generate
    end

    desc "version", "prints version"
    def version
      puts VERSION
    end
  end
end
