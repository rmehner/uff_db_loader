RSpec.describe UffDbLoader do
  it "has a version number" do
    expect(UffDbLoader::VERSION).not_to be nil
  end

  describe "configure" do
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
  end
end
