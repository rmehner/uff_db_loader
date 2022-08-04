# frozen_string_literal: true

require "uff_db_loader/version"
require "configuration"

module UffDbLoader
  require "railtie"

  def self.config
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(config)
  end

  def self.dump_filename(environment)
    File.join(
      config.dumps_directory,
      Time.now.strftime("#{config.app_name}_#{environment}_%Y_%m_%d_%H_%M_%S.#{config.database_system.dump_extension}")
    )
  end

  def self.dump_from(environment)
    FileUtils.mkdir_p(config.dumps_directory)

    puts "⬇️  Creating dump ..."

    target = dump_filename(environment)

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
      .gsub("%app_name%", config.app_name)
  end

  def self.ensure_valid_environment!(environment)
    unless config.environments.include?(environment)
      raise ForbiddenEnvironmentError, "Invalid environment: #{environment}."
    end
  end

  def self.restore_command(database_name, result_file_path)
    config.database_system.restore_command(database_name, result_file_path)
  end

  def self.prune_dump_directory
    FileUtils.rm_rf("#{config.dumps_directory}/.", secure: true)
  end

  def self.drop_database(database_name)
    config.database_system.drop_database(database_name)
  end

  def self.databases
    lines = config.database_system.list_databases(config.db_name)
    lines.split("\n").map(&:strip).select do |line|
      line =~ /#{config.app_name}_(#{config.environments.join("|")})_(\d|_)+/
    end
  end

  class ForbiddenEnvironmentError < StandardError; end

  class UnknownDatabaseSystem < StandardError; end
end
