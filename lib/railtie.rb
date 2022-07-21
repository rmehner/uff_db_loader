# frozen_string_literal: true

require "uff_db_loader"
require "rails"

module UffDbLoader
  class Railtie < Rails::Railtie
    railtie_name "uff_db_loader"

    initializer "uff_db_loader.setup" do |app|
      UffDbLoader.configure do |config|
        config.dumps_directory = Rails.root.join("dumps")
        config.database_config_file = Rails.root.join("config", "database.yml")
        config.app_name = (Rails.application.class.respond_to?(:parent_name) ? Rails.application.class.parent_name : Rails.application.class.module_parent_name).downcase
      end
    end

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/uff_db_loader/tasks/*.rake").each { |f| load f }
    end
  end
end
