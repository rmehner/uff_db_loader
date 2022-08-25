# frozen_string_literal: true

require "uff_db_loader/version"
require "configuration"

module UffDbLoader
  require "railtie"

  def self.config
    @configuration ||= Configuration.new
  end

  def self.database_name_file
    Rails.root.join("tmp", "uff_db_loader_database_name")
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

  def self.database_name_template(old_database_name)
    "<%= UffDbLoader.current_database_name || '#{old_database_name}' %>"
  end

  def self.setup_dynamic_database_name_in_config
    old_database_name = Rails.configuration.database_configuration["development"]["database"]

    return false if old_database_name.nil?

    old_config = File.read(UffDbLoader.config.database_config_file)
    new_config = old_config.sub(old_database_name, database_name_template(old_database_name))
    File.write(UffDbLoader.config.database_config_file, new_config)
  end

  def self.current_database_name
    database_name = File.read(database_name_file).strip
    return if database_name.blank?
    database_name
  rescue IOError, Errno::ENOENT => e
    puts "Could not read #{database_name_file}. #{e.message}"
  end

  def self.remember_database_name(database_name)
    File.write(database_name_file, database_name)
  end

  def self.ensure_installation!
    unless File.read(UffDbLoader.config.database_config_file).include?("UffDbLoader.current_database_name")
      raise InstallationDidNotRunError, "Please run bin/rails uff_db_loader:install"
    end
  end

  def self.dump_file_path(database_name)
    File.join(
      config.dumps_directory,
      "#{database_name}.#{config.database_system.dump_extension}"
    )
  end

  def self.load_dump_into_database(database_name)
    UffDbLoader.drop_database(database_name)
    UffDbLoader.create_database(database_name)

    puts "🗂  Created database #{database_name}"

    dump_file_path = dump_file_path(database_name)

    command_successful = system(restore_command(database_name, dump_file_path))
    raise "Command did not run succesful: #{restore_command(database_name, dump_file_path)}" unless command_successful

    puts "✅ Succesfully loaded #{dump_file_path} into #{database_name}"

    remember_database_name(database_name)
    system("bin/rails restart")

    puts "♻️  Restarted rails server with new database."
  end

  class ForbiddenEnvironmentError < StandardError; end

  class UnknownDatabaseSystem < StandardError; end

  class InstallationDidNotRunError < StandardError; end
end
