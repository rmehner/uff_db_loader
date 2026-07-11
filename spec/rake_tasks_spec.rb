require "active_record"
require "fileutils"
require "pathname"
require "rake"
require "tmpdir"

RSpec.describe "rake tasks" do
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
end
