require_relative 'lib/suivi/version'

Gem::Specification.new do |s|
  s.name          = "suivi"
  s.version       = Suivi::VERSION
  s.authors       = ["PhilippePerret"]
  s.email         = ["philippe.perret@yahoo.fr"]

  s.summary       = %q{Pour le suivi de transactions}
  s.description   = %q{Ce module permet de suivre les transactions par fichiers CSV}
  s.homepage      = "https://github.com/PhilippePerret/hem-suivi"
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  s.metadata["allowed_push_host"] = "https://github.com/PhilippePerret/hem-suivi"

  s.add_dependency 'csv'

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-color'

  s.metadata["homepage_uri"] = s.homepage
  s.metadata["source_code_uri"] = "https://github.com/PhilippePerret/hem-suivi"
  s.metadata["changelog_uri"] = "https://github.com/PhilippePerret/hem-suivi/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|features)/}) }
  end
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]
end
