# frozen_string_literal: true

require "fileutils"
require "rbconfig"

Dir.chdir(__dir__) do
  abort "forme-ruby source installation requires Rust/Cargo. Install a supported platform gem or install Rust first." unless system("cargo", "--version", out: File::NULL)
  abort "Forme native build failed" unless system("cargo", "build", "--locked", "--release", "--manifest-path", File.join(__dir__, "Cargo.toml"))
  extension = RbConfig::CONFIG["host_os"].include?("darwin") ? "dylib" : "so"
  source = File.join(__dir__, "target", "release", "libforme_pdf_native.#{extension}")
  destination = File.expand_path("../../lib/forme_pdf/native", __dir__)
  FileUtils.mkdir_p(destination)
  FileUtils.cp(source, destination)
  File.write("Makefile", "all:\n\t@true\ninstall:\n\t@true\nclean:\n\t@true\n")
end
