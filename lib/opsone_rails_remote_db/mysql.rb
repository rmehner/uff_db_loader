# frozen_string_literal: true

module OpsoneRailsRemoteDb
  module Mysql
    def self.dump_command_template
      "ssh %user%@%host% \"docker exec -i #{APP_NAME}_%environment%_db sh -c 'exec mysqldump --opt --no-tablespaces -uroot -p\"\$MYSQL_ROOT_PASSWORD\" %database%'\" > %target%"
    end

    def self.restore_command(database_name, result_file_path)
      "mysql -uroot #{database_name} < #{result_file_path}"
    end
  end
end
