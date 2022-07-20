# frozen_string_literal: true

require "uff_db_loader/postgresql"
require "uff_db_loader/mysql"

module UffDbLoader
  class Configuration
    attr_accessor :environments, :host, :user, :db_name, :db_system

    def initialize
      @environments = %w[staging production]
      @host = nil
      @user = nil
      @db_name = nil
      @db_system = nil
    end

    def database
      db_name || user
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
