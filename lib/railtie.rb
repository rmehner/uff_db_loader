# frozen_string_literal: true

require 'opsone_rails_remote_db'
require 'rails'

module OpsOneRemoteDb
  class Railtie < Rails::Railtie
    railtie_name 'opsone_rails_remote_db'

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/opsone_rails_remote_db/tasks/*.rake").each { |f| load f }
    end
  end
end
