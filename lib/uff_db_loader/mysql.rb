# frozen_string_literal: true

module UffDbLoader
  module Mysql
    def self.dump_extension
      "sql"
    end

    def self.dump_command_template
      "ssh %user%@%host% \"docker exec -i %container_name% sh -c 'exec mysqldump --opt --single-transaction --routines --triggers --events --no-tablespaces -uroot -p\"\\$MYSQL_ROOT_PASSWORD\" %database%'\" > %target%"
    end

    def self.restore_command(database_name, result_file_path, config)
      "#{File.join(config.local_restore_command_path || "mysql")} -uroot #{database_name} < #{result_file_path}"
    end

    def self.list_databases
      ActiveRecord::Base.connection.execute("SHOW DATABASES;").to_a.flatten
    end

    def self.create_database(database_name)
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{database_name};")
    end

    def self.drop_database(database_name)
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{database_name};")
    end
  end
end
