# frozen_string_literal: true

require 'rails_remote_db'
require 'rails'

module RailsRemoteDb
  class Railtie < Rails::Railtie
    railtie_name 'rails_remote_db'

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/rails_remote_db/tasks/*.rake").each { |f| load f }
    end
  end
end
