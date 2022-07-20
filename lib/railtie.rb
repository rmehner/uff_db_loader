# frozen_string_literal: true

require 'uff_db_loader'
require 'rails'

module UffDbLoader
  class Railtie < Rails::Railtie
    railtie_name 'uff_db_loader'

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/uff_db_loader/tasks/*.rake").each { |f| load f }
    end
  end
end
