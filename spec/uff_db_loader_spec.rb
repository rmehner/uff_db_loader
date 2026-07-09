RSpec.describe UffDbLoader do
  it "has a version number" do
    expect(UffDbLoader::VERSION).not_to be nil
  end

  describe "uff_db_loader:load" do
    let(:rails_root) { Pathname.new(Dir.mktmpdir) }
    let(:rails_configuration) do
      Struct.new(:database_configuration).new(
        {"development" => {"database" => "uff_db_loader_development"}}
      )
    end
    let(:rails_application) { Struct.new(:root, :configuration).new(rails_root, rails_configuration) }

    around do |example|
      original_application = Rake.application

      Rake.application = Rake::Application.new
      Rake::Task.define_task(:environment)
      load File.expand_path("../lib/uff_db_loader/tasks/uff_db_loader.rake", __dir__)

      example.run
    ensure
      Rake.application = original_application
    end

    before do
      FileUtils.mkdir_p(rails_root.join("tmp"))
      stub_const("Rails", rails_application)
      allow(ActiveRecord::Base).to receive(:remove_connection)
      allow(ActiveRecord::Base).to receive(:establish_connection)
      allow(ActiveRecord::Base).to receive(:connection)

      UffDbLoader.reset
      UffDbLoader.configure do |config|
        config.environments = ["staging"]
      end
    end

    after do
      FileUtils.rm_rf(rails_root)
    end

    it "loads the fresh dump after clearing a stale selected database" do
      prompt = instance_double(TTY::Prompt, select: "staging")
      loaded_database_name = nil

      UffDbLoader.remember_database_name("uff_db_loader_staging_2026_04_29_23_10_33")

      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      allow(UffDbLoader).to receive(:ensure_installation!)
      allow(UffDbLoader).to receive(:dump_from).with("staging").and_return("/tmp/uff_db_loader_staging_2026_07_09_11_49_38.dump")
      allow(UffDbLoader).to receive(:load_dump_into_database) { |database_name|
        expect(UffDbLoader.current_database_name).to be_nil

        loaded_database_name = database_name
      }
      allow(UffDbLoader).to receive(:log)

      Rake::Task["uff_db_loader:load"].invoke

      expect(loaded_database_name).to eq("uff_db_loader_staging_2026_07_09_11_49_38")
    end

    it "does not create a dump when the default database is missing" do
      allow(UffDbLoader).to receive(:ensure_installation!)
      allow(UffDbLoader).to receive(:dump_from)
      allow(ActiveRecord::Base).to receive(:connection).and_raise(
        ActiveRecord::NoDatabaseError.new("database does not exist")
      )

      expect do
        Rake::Task["uff_db_loader:load"].invoke
      end.to raise_error UffDbLoader::DefaultDatabaseNotFoundError

      expect(UffDbLoader).not_to have_received(:dump_from)
    end
  end

  describe "configure" do
    before { UffDbLoader.reset }

    it "allows to set a container_name dynamically" do
      UffDbLoader.configure do |config|
        config.container_name = ->(app_name, environment) { "#{app_name}_#{environment}_db_v15" }
      end

      expect(UffDbLoader.send(:container_name, "sandbox")).to eq "uff_db_loader_sandbox_db_v15"
    end

    it "allows to set a container_name statically" do
      UffDbLoader.configure do |config|
        config.container_name = "uff_db_loader_db_v15"
      end

      expect(UffDbLoader.send(:container_name, "sandbox")).to eq "uff_db_loader_db_v15"
    end

    it "allows to set a ssh_user dynamically" do
      UffDbLoader.configure do |config|
        config.ssh_user = ->(app_name, environment) { "#{app_name}_#{environment}_ssh" }
      end

      expect(UffDbLoader.send(:ssh_user, "sandbox")).to eq "uff_db_loader_sandbox_ssh"
    end

    it "allows to set a ssh_user statically" do
      UffDbLoader.configure do |config|
        config.ssh_user = "deploy-user"
      end

      expect(UffDbLoader.send(:ssh_user, "sandbox")).to eq "deploy-user"
    end

    it "allows to set a ssh_host dynamically" do
      UffDbLoader.configure do |config|
        config.ssh_host = ->(_app_name, environment) { "#{environment}.example.com" }
      end

      expect(UffDbLoader.send(:ssh_host, "sandbox")).to eq "sandbox.example.com"
    end

    it "allows to set a ssh_host statically" do
      UffDbLoader.configure do |config|
        config.ssh_host = "db.example.com"
      end

      expect(UffDbLoader.send(:ssh_host, "sandbox")).to eq "db.example.com"
    end

    it "allows to set a db_name dynamically" do
      UffDbLoader.configure do |config|
        config.db_name = ->(app_name, environment) { "#{app_name}_#{environment}_database" }
      end

      expect(UffDbLoader.send(:database_name, "sandbox")).to eq "uff_db_loader_sandbox_database"
    end

    it "allows to set a db_name statically" do
      UffDbLoader.configure do |config|
        config.db_name = "custom_database"
      end

      expect(UffDbLoader.send(:database_name, "sandbox")).to eq "custom_database"
    end

    it "falls back to ssh_user when db_name is not configured" do
      UffDbLoader.configure do |config|
        config.ssh_user = "deploy-user"
      end

      expect(UffDbLoader.send(:database_name, "sandbox")).to eq "deploy-user"
    end
  end
end
