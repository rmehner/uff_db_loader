# frozen_string_literal: true

require "uff_db_loader/postgresql"
require "uff_db_loader/mysql"

module UffDbLoader
  class Configuration
    attr_accessor(
      :environments,
      :ssh_host,
      :ssh_user,
      :db_name,
      :db_system,
      :app_name,
      :dumps_directory,
      :database_config_file,
      :container_name,
      :local_mysql_cli_path,
      :local_psql_cli_path
    )

    def initialize
      @environments = nil
      @ssh_host = nil
      @ssh_user = nil
      @db_name = nil
      @db_system = nil
      @app_name = Dir.pwd.split("/").last
      @dumps_directory = File.join(Dir.pwd, "dumps")
      @database_config_file = File.join(Dir.pwd, "config", "database.yml")
      @container_name = nil
      @local_mysql_cli_path = nil
      @local_psql_cli_path = nil
    end

    def database
      db_name || ssh_user
    end

    def database_system
      case db_system.to_sym
      when :postgresql
        UffDbLoader::Postgresql
      when :mysql
        UffDbLoader::Mysql
      else
        raise UnknownDatabaseSystem, "Could not identify database system. Use `config.db_system` to configure it."
      end
    end
  end
end
