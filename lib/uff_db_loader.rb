# frozen_string_literal: true

require "uff_db_loader/version"
require "configuration"

module UffDbLoader
  RAILS_ROOT = Dir.pwd
  APP_NAME = RAILS_ROOT.split('/').last
  DUMP_DIRECTORY = File.join(RAILS_ROOT, 'dumps')
  DATABASE_CONFIG_FILE = File.join(RAILS_ROOT, 'config', 'database.yml').to_s

  require "railtie" if defined?(Rails)

  class << self
    attr_accessor :config
  end

  def self.config
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(config)
  end

  def self.dump_from(environment)
    raise "Invalid environment: #{environment}." unless config.environments.include?(environment)

    FileUtils.mkdir_p(DUMP_DIRECTORY)

    puts "⬇️  Creating dump ..."

    target = File.join(DUMP_DIRECTORY, Time.now.strftime("#{APP_NAME}_#{environment}_%Y_%m_%d_%H_%M_%S.dump"))
    command_successful = system(dump_command(environment, target))
    raise "Command did not run succesful: #{dump_command(environment, target)}" unless command_successful

    puts "✅ Succesfully dumped to #{target}"

    target
  end

  def self.dump_command(environment, target)
    config
      .database_system
      .dump_command_template
      .gsub("%environment%", environment)
      .gsub("%host%", config.ssh_host)
      .gsub("%user%", config.ssh_user)
      .gsub("%database%", config.database)
      .gsub("%target%", target)
  end

  def self.ensure_valid_environment!(environment)
    unless config.environments.include?(environment)
      raise ForbiddenEnvironmentError, "Invalid environment: #{environment}."
    end
  end

  def self.restore_command(database_name, result_file_path)
    config.database_system.restore_command(database_name, result_file_path)
  end

  class ForbiddenEnvironmentError < StandardError; end

  class UnknownDatabaseSystem < StandardError; end
end
