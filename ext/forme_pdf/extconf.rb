# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "open3"
require "json"
require "tempfile"

keep_build = ARGV.delete("--keep-build")
Dir.chdir(__dir__) do
  abort "forme-ruby source installation requires Rust/Cargo. Install a supported platform gem or install Rust first." unless system("cargo", "--version", out: File::NULL)
  output, status = Open3.capture2("cargo", "build", "--locked", "--release", "--message-format=json", "--target-dir", File.join(__dir__, "target"), "--manifest-path", File.join(__dir__, "Cargo.toml"))
  abort "Forme native build failed" unless status.success?
  extension = RbConfig::CONFIG["host_os"].include?("darwin") ? "dylib" : "so"
  artifacts = output.lines.filter_map do |line|
    record = JSON.parse(line)
    record.fetch("filenames", []) if record["reason"] == "compiler-artifact" && record.dig("target", "name") == "forme_pdf_native"
  end.flatten
  source = artifacts.find { |path| File.basename(path) == "libforme_pdf_native.#{extension}" }
  abort "Cargo did not produce a Forme shared library for this platform" unless source
  destination = File.expand_path("../../lib/forme_pdf/native", __dir__)
  FileUtils.mkdir_p(destination)
  # Replace the inode atomically: overwriting a loaded signed dylib breaks macOS code-signing caches.
  Tempfile.create(["forme-native-", ".tmp"], destination) do |temporary|
    FileUtils.cp(source, temporary.path)
    temporary.chmod(0o644)
    File.rename(temporary.path, File.join(destination, File.basename(source)))
  end
  FileUtils.rm_rf(File.join(__dir__, "target")) unless keep_build
  File.write("Makefile", "all:\n\t@true\ninstall:\n\t@true\nclean:\n\t@true\n")
end
