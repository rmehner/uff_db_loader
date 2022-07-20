# frozen_string_literal: true

module OpsoneRailsRemoteDb
  module Postgresql
    def self.dump_command_template
      "ssh %user%@%host% \"docker exec -i #{APP_NAME}_%environment%_db sh -c 'exec pg_dump --username \\$POSTGRES_USER --clean --no-owner --no-acl --format=c %database%'\" > %target%"
    end

    def self.restore_command(database_name, result_file_path)
      "pg_restore --username postgres --clean --if-exists --no-owner --no-acl --dbname #{database_name} #{result_file_path}"
    end
  end
end
