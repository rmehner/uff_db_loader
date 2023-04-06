# frozen_string_literal: true

require "uff_db_loader/version"
require "configuration"

module UffDbLoader
  require "railtie"

  TIMESTAMP_FORMAT = "%Y_%m_%d_%H_%M_%S"
  TIMESTAMP_LENGTH = Time.now.strftime(TIMESTAMP_FORMAT).size

  class << self
    def config
      @configuration ||= Configuration.new
    end

    def reset
      @configuration = Configuration.new
    end

    def configure
      yield(config)
    end

    def restart_rails_server
      system("bin/rails restart")
    end

    def dump_from(environment)
      FileUtils.mkdir_p(config.dumps_directory)

      puts "⬇️  Creating dump ..."

      target = dump_file_path(Time.now.strftime("#{config.app_name}_#{environment}_#{TIMESTAMP_FORMAT}"))

      command_successful = system(dump_command(environment, target))
      raise "Command did not run succesful: #{dump_command(environment, target)}" unless command_successful

      puts "✅ Succesfully dumped to #{target}"

      target
    end

    def ensure_valid_environment!(environment)
      unless config.environments.include?(environment)
        raise ForbiddenEnvironmentError, "Invalid environment: #{environment}."
      end
    end

    def prune_dump_directory
      FileUtils.rm_f(
        FileList["#{config.dumps_directory}/*"].exclude(dump_file_path(current_database_name)).to_a
      )
    end

    def create_database(database_name)
      config.database_system.create_database(database_name)
    end

    def drop_database(database_name)
      config.database_system.drop_database(database_name)
    end

    def databases
      config.database_system.list_databases
        .select { |line| line =~ /#{config.app_name}_(#{config.environments.join("|")})_(\d|_)+/ }
        .sort_by { |database| database[-TIMESTAMP_LENGTH..] }
        .reverse
    end

    def dumps
      Dir
        .glob("#{config.dumps_directory}/#{config.app_name}*")
        .map { |f| File.basename(f, ".*") }
        .sort_by { |dump| dump[-TIMESTAMP_LENGTH..] }
        .reverse
    end

    def setup_dynamic_database_name_in_config
      old_database_name = Rails.configuration.database_configuration["development"]["database"]

      return false if old_database_name.nil?

      old_config = File.read(UffDbLoader.config.database_config_file)
      new_config = old_config.sub(old_database_name, database_name_template(old_database_name))
      File.write(UffDbLoader.config.database_config_file, new_config)
    end

    def current_database_name
      File.read(database_name_file).strip.presence
    rescue IOError, Errno::ENOENT
      # We expect this file to be missing in non-dev environments.
    end

    def remember_database_name(database_name)
      File.write(database_name_file, database_name)
    end

    def ensure_installation!
      unless File.read(UffDbLoader.config.database_config_file).include?("UffDbLoader.current_database_name")
        raise InstallationDidNotRunError, "Please run bin/rails uff_db_loader:install"
      end
    end

    def load_dump_into_database(database_name)
      UffDbLoader.drop_database(database_name)
      UffDbLoader.create_database(database_name)

      puts "🗂  Created database #{database_name}"

      dump_file_path = dump_file_path(database_name)

      command_successful = system(restore_command(database_name, dump_file_path))
      raise "Command did not run succesful: #{restore_command(database_name, dump_file_path)}" unless command_successful

      puts "✅ Succesfully loaded #{dump_file_path} into #{database_name}"

      remember_database_name(database_name)
      restart_rails_server

      puts "♻️  Restarted rails server with new database."
    end

    def initializer_path
      Rails.root.join("config", "initializers", "uff_db_loader.rb")
    end

    def create_initializer
      template = ERB.new(File.read(initializer_template_path))

      File.write(
        initializer_path,
        template.result_with_hash(
          used_database_system: used_database_system,
          environments: environments
        )
      )
    end

    private

    def container_name(environment)
      return "#{config.app_name}_#{environment}_db" if config.container_name.blank?
      return config.container_name unless config.container_name.respond_to? :call

      config.container_name.call(config.app_name, environment)
    end

    def initializer_template_path
      File.join(__dir__, "uff_db_loader", "templates", "uff_db_loader_initializer.erb")
    end

    def database_name_file
      Rails.root.join("tmp", "uff_db_loader_database_name")
    end

    def dump_filename(environment)
      File.join(
        config.dumps_directory,
        Time.now.strftime("#{config.app_name}_#{environment}_%Y_%m_%d_%H_%M_%S.#{config.database_system.dump_extension}")
      )
    end

    def dump_command(environment, target)
      config
        .database_system
        .dump_command_template
        .gsub("%host%", config.ssh_host)
        .gsub("%user%", config.ssh_user)
        .gsub("%database%", config.database)
        .gsub("%target%", target)
        .gsub("%container_name%", container_name(environment))
    end

    def restore_command(database_name, result_file_path)
      config.database_system.restore_command(database_name, result_file_path)
    end

    def database_name_template(old_database_name)
      "<%= defined?(UffDbLoader) && UffDbLoader.current_database_name || '#{old_database_name}' %>"
    end

    def dump_file_path(database_name)
      File.join(
        config.dumps_directory,
        "#{database_name}.#{config.database_system.dump_extension}"
      )
    end

    def used_database_system
      case Rails.configuration.database_configuration["development"]["adapter"]
      when "mysql", "mysql2", "trilogy"
        ":mysql"
      when "postgresql"
        ":postgresql"
      else
        puts "🙃 Could not automatically determine your used database system. Please adapt in the initializer."
        ":unknown"
      end
    end

    def environments
      ActiveRecord::Base.configurations.configurations.to_a.map(&:env_name) - ["default", "test", "development"]
    end

    class ForbiddenEnvironmentError < StandardError; end

    class UnknownDatabaseSystem < StandardError; end

    class InstallationDidNotRunError < StandardError; end
  end
end
