# frozen_string_literal: true

require "rake"
require "rspec/core/rake_task"
require "rubygems/package"
require "fileutils"

RSpec::Core::RakeTask.new(:spec) { |task| task.ruby_opts = ["-Ilib"] }
task default: :spec

desc "Compile the native library into this checkout"
task :compile do
  ruby "ext/forme_pdf/extconf.rb", "--keep-build"
end

desc "Build source gem, or precompiled gem with package[native]"
task :package, [:kind] do |_task, args|
  abort "Generate notices with ruby script/notices.rb first" unless File.file?("THIRD_PARTY_LICENSES.txt")
  spec = Gem::Specification.load("forme-ruby.gemspec")
  if args[:kind] == "native"
    extension = RbConfig::CONFIG["host_os"].include?("darwin") ? "dylib" : "so"
    libraries = Dir["lib/forme_pdf/native/libforme_pdf_native.#{extension}"]
    abort "Run rake compile first" if libraries.empty?
    platform = Gem::Platform.local
    abort "Musl binaries are not supported" if platform.to_s.include?("musl") || RbConfig::CONFIG["host_os"].include?("musl")
    platform = Gem::Platform.new("x86_64-linux-gnu") if platform.cpu == "x86_64" && platform.os == "linux"
    supported = (platform.cpu == "arm64" && platform.os == "darwin") || platform.to_s == "x86_64-linux-gnu"
    abort "Unsupported binary platform #{platform}" unless supported
    spec.platform = (platform.os == "darwin") ? Gem::Platform.new("arm64-darwin") : platform
    spec.extensions = []
    spec.files = spec.files.reject { |name| name.start_with?("ext/") } + libraries
  elsif args[:kind] && args[:kind] != "source"
    abort "Use package[source] or package[native]"
  end
  FileUtils.mkdir_p("pkg")
  file = Gem::Package.build(spec)
  FileUtils.mv(file, File.join("pkg", file))
end
