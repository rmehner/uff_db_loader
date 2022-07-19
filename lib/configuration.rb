module OpsoneRailsRemoteDb
  class Configuration
    attr_accessor :environments, :host, :user, :db_name

    def initialize
      @environments = ['staging', 'production']
      @host = nil
      @user = nil
      @db_name = nil
    end

    def database
      db_name || user
    end
  end
end
