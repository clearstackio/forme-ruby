# frozen_string_literal: true

require_relative "lib/forme_pdf/version"
Gem::Specification.new do |spec|
  spec.name = "forme-ruby"
  spec.version = FormePDF::VERSION
  spec.authors = ["Ajaya Agrawalla"]
  spec.email = ["ajaya@clearstack.io"]
  spec.summary = "Native HTML to PDF rendering for Ruby and Rails"
  spec.description = "Independent Ruby bindings for the Rust Forme HTML renderer. No browser, Node.js, WebAssembly or separate rendering service."
  spec.homepage = "https://github.com/clearstackio/forme-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"
  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "documentation_uri" => "#{spec.homepage}/blob/main/docs/README.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true",
    "allowed_push_host" => "https://rubygems.org"
  }
  spec.files = Dir["lib/**/*.rb", "ext/forme_pdf/{Cargo.toml,Cargo.lock,extconf.rb}", "ext/forme_pdf/src/**/*.rs", "docs/**/*.md", "examples/**/*.rb", "CONTRIBUTING.md", "CODE_OF_CONDUCT.md", "SECURITY.md", "README.md", "LICENSE", "CHANGELOG.md", "NOTICE", "THIRD_PARTY_LICENSES.txt"]
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/forme_pdf/extconf.rb"]
  spec.add_dependency "ffi", "~> 1.17"
  spec.add_dependency "base64", "~> 0.2"
  spec.add_dependency "json", ">= 2.0", "< 3"
end
