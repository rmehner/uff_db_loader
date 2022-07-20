require_relative 'lib/uff_db_loader/version'

Gem::Specification.new do |spec|
  spec.name          = "uff_db_loader"
  spec.version       = UffDbLoader::VERSION
  spec.authors       = ["UFF"]
  spec.email         = ["robin@coding-robin.de"]

  spec.summary       = %q{Allows to dump, download and restore databases from docker servers.}
  spec.description   = %q{Allows to dump, download and restore databases from servers with a specific docker setup, that UFF uses commonly.}
  spec.homepage      = "https://coding-robin.de"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rmehner/uff_db_loader"
  spec.metadata["changelog_uri"] = "https://github.com/rmehner/uff_db_loader"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency 'tty-prompt'
end
