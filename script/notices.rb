# frozen_string_literal: true

require "json"
require "open3"

output, status = Open3.capture2("cargo", "metadata", "--locked", "--format-version", "1", "--manifest-path", "ext/forme_pdf/Cargo.toml")
abort "Cannot resolve dependency licenses" unless status.success?
packages = JSON.parse(output).fetch("packages")
text = ["Third-party dependencies for forme-ruby (generated from Cargo.lock)."]
packages.sort_by { |package| [package.fetch("name"), package.fetch("version")] }.each do |package|
  next if package.fetch("name") == "forme-pdf-native"
  directory = File.dirname(package.fetch("manifest_path"))
  candidates = Dir[File.join(directory, "{LICENSE*,LICENCE*,COPYING*,license*,licence*}")].select { |path| File.file?(path) }
  if candidates.empty? && package.fetch("name").start_with?("forme-")
    candidates = Dir[File.join(File.dirname(directory), "LICENSE*")].select { |path| File.file?(path) }
  end
  if candidates.empty?
    fallback = File.join(__dir__, "licenses", "#{package.fetch("name")}-#{package.fetch("version")}")
    candidates = Dir[File.join(fallback, "LICENSE*")].sort
  end
  # Case-insensitive filesystems may return the same file for both glob cases.
  candidates = candidates.uniq.sort
  abort "Missing license text for #{package.fetch("name")} #{package.fetch("version")}" if candidates.empty?
  text << "\n#{package.fetch("name")} #{package.fetch("version")} — #{package["license"]}\n#{package["repository"]}"
  candidates.each { |path| text << File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace) }
end
File.write("THIRD_PARTY_LICENSES.txt", text.join("\n\n").gsub("\r\n", "\n").gsub(/[ \t]+$/, ""))
