require_relative "lib/volume_sweeper/version"

Gem::Specification.new do |spec|
  spec.name    = "volume_sweeper"
  spec.version = VolumeSweeper::VERSION
  spec.date    = Date.today.to_s
  spec.authors = ["Abdullah Barrak"]
  spec.email   = ["abdullah@abarrak.com"]

  spec.summary     = "A CLI for block volumes sweeping and cleanup"
  spec.description = "This is a scanning tool for cloud infrastructure cross referenced with related clusters. "
  spec.homepage    = "https://github.com/abarrak/volume_sweeper"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = "https://github.com/abarrak/volume_sweeper"
  spec.metadata["changelog_uri"]     = "https://github.com/abarrak/volume_sweeper/releases"
  spec.metadata["documentation_uri"] = "https://www.rubydoc.info/gems/volume_sweeper"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir         = "exe"
  spec.executables    = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths  = ["lib"]

  spec.add_dependency "cowsay", "~> 0.3.0"
  spec.add_dependency "oci", "~> 2.20"
  spec.add_dependency "kubeclient", "~> 4.11"
  spec.add_dependency "prometheus-client", "~> 4.2"
  spec.add_dependency "activesupport", "~> 7.1"
  spec.add_dependency "mail", "~> 2.8"
  spec.add_dependency "network-client", "~> 3"
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "simplecov", "0.22.0"
  spec.add_development_dependency "simplecov-cobertura", "~> 2.1.0"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 1.0"
  spec.add_development_dependency "mailcatcher"
  spec.add_development_dependency "standard"
end
