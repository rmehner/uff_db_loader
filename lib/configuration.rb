# frozen_string_literal: true

require "uff_db_loader/postgresql"
require "uff_db_loader/mysql"

module UffDbLoader
  class Configuration
    attr_accessor :environments, :ssh_host, :ssh_user, :db_name, :db_system, :app_name, :dumps_directory, :database_config_file

    def initialize
      @environments = %w[staging production]
      @ssh_host = nil
      @ssh_user = nil
      @db_name = nil
      @db_system = nil
      @app_name = ''
      @dumps_directory = File.join(Dir.pwd, 'dumps')
      @database_config_file = File.join(Dir.pwd, 'config', 'database.yml')
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
        raise UnknownDatabaseSystem, 'Could not identify database system. Use `config.db_system` to configure it.'
      end
    end
  end
end
