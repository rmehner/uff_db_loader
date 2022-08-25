# frozen_string_literal: true

module UffDbLoader
  module Mysql
    def self.dump_extension
      "sql"
    end

    def self.dump_command_template
      "ssh %user%@%host% \"docker exec -i %app_name%_%environment%_db sh -c 'exec mysqldump --opt --no-tablespaces -uroot -p\"\\$MYSQL_ROOT_PASSWORD\" %database%'\" > %target%"
    end

    def self.restore_command(database_name, result_file_path)
      "mysql -uroot #{database_name} < #{result_file_path}"
    end

    def self.list_databases
      ActiveRecord::Base.connection.execute("SHOW DATABASES;").to_a.flatten
    end

    def self.create_database
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{database_name};")
    end

    def self.drop_database
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{database_name};")
    end
  end
end
