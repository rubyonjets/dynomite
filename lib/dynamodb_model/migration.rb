class DynamodbModel::Migration
  class << self
    def up
      puts "Running up migration for #{self.class.name}"
    end

    def create_table(table_name)
      dsl = Dsl.new(table_name)
      yield(dsl)
      dsl.execute
    end
  end
end
