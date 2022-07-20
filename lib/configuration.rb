# frozen_string_literal: true

require "opsone_rails_remote_db/postgresql"
require "opsone_rails_remote_db/mysql"

module OpsoneRailsRemoteDb
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
        OpsoneRailsRemoteDb::Postgresql
      when :mysql
        OpsoneRailsRemoteDb::Mysql
      else
        raise UnknownDatabaseSystem, 'Could not identify database system. Use `config.db_system` to configure it.'
      end
    end
  end
end
