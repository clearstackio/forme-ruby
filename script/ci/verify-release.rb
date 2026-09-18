# frozen_string_literal: true

require "rubygems/package"
require_relative "../../lib/forme_pdf/version"

packages = Dir["pkg/*.gem"]
abort "Expected exactly three packages" unless packages.size == 3
platforms = packages.map do |file|
  package = Gem::Package.new(file)
  package.verify
  spec = package.spec
  abort "Unexpected name or version in #{file}" unless spec.name == "forme-ruby" && spec.version.to_s == FormePDF::VERSION
  %w[LICENSE NOTICE THIRD_PARTY_LICENSES.txt README.md].each do |required|
    abort "Missing #{required} in #{file}" unless spec.files.include?(required)
  end
  platform = spec.platform.to_s
  expected_extensions = (platform == "ruby") ? ["ext/forme_pdf/extconf.rb"] : []
  abort "Invalid build hook in #{file}" unless spec.extensions == expected_extensions
  if platform != "ruby"
    extension = (platform == "arm64-darwin") ? "dylib" : "so"
    abort "Missing native library in #{file}" unless spec.files.include?("lib/forme_pdf/native/libforme_pdf_native.#{extension}")
  end
  platform
end
abort "Unexpected or duplicate platform packages" unless platforms.sort == %w[arm64-darwin ruby x86_64-linux-gnu]
puts "Validated source, macOS ARM and Linux AMD64 release packages"
