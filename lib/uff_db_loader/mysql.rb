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
      # My best guess so far:
      # ActiveRecord::Base.connection.execute('SHOW DATABASES').values.flatten

      # Psql for reference
      # ActiveRecord::Base
      #   .connection
      #   .execute("SELECT datname FROM pg_database JOIN pg_authid ON pg_database.datdba = pg_authid.oid WHERE rolname = '#{rolename}';")
      #   .values
      #   .flatten
    end

    def self.create_database
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{database_name};")
    end

    def self.drop_database
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{database_name};")
    end
  end
end
