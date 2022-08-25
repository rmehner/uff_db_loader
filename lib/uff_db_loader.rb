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

  def self.create_database(database_name)
    config.database_system.create_database(database_name)
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
    config.database_system.list_databases.select do |line|
      line =~ /#{config.app_name}_(#{config.environments.join("|")})_(\d|_)+/
    end
  end

  def self.replace_database_name_in_config(new_database_name)
    old_database_name = Rails.configuration.database_configuration["development"]["database"]

    return false if old_database_name.nil?

    old_config = File.read(UffDbLoader.config.database_config_file)
    new_config = old_config.sub(old_database_name, new_database_name)
    File.write(UffDbLoader.config.database_config_file, new_config)
  end

  class ForbiddenEnvironmentError < StandardError; end

  class UnknownDatabaseSystem < StandardError; end
end
