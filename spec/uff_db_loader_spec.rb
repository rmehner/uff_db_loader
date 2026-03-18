RSpec.describe UffDbLoader do
  it "has a version number" do
    expect(UffDbLoader::VERSION).not_to be nil
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
