# frozen_string_literal: true

require "opsone_rails_remote_db/version"
require "configuration"

module OpsoneRailsRemoteDb
  RAILS_ROOT = Dir.pwd
  APP_NAME = RAILS_ROOT.split('/').last
  DUMP_DIRECTORY = File.join(RAILS_ROOT, 'dumps')
  COMMAND_TEMPLATE = "ssh %user%@%host% \"docker exec -i #{APP_NAME}_%environment%_db sh -c 'exec pg_dump --username \\$POSTGRES_USER --clean --no-owner --no-acl --format=c %database%'\" > %target%".freeze
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

    filename = Time.now.strftime("#{APP_NAME}_#{environment}_%Y_%m_%d_%H_%M_%S.dump")
    target = File.join(DUMP_DIRECTORY, filename).to_s

    # Ensure dump directory exists!
    # Ensure the role has superuser!

    command_to_run =
      COMMAND_TEMPLATE
      .gsub("%environment%", environment)
      .gsub("%host%", config.host)
      .gsub("%user%", config.user)
      .gsub("%database%", config.database)
      .gsub("%target%", target)

    puts "⬇️  Creating dump ..."
    command_successful = system(command_to_run)
    raise "Command did not run succesful: #{command_to_run}" unless command_successful

    puts "✅ Succesfully dumped to #{target}"

    target
  end

  class ForbiddenEnvironmentError < StandardError; end
end
