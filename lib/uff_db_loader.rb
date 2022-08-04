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

  class ForbiddenEnvironmentError < StandardError; end

  class UnknownDatabaseSystem < StandardError; end
end
