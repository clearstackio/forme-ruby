# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "rbconfig"

Dir["pkg/*.gem"].each do |package|
  Dir.mktmpdir("forme-installed-") do |directory|
    env = {"GEM_HOME" => directory, "GEM_PATH" => directory, "RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil}
    abort "Gem installation failed: #{package}" unless system(env, RbConfig.ruby, "-S", "gem", "install", File.expand_path(package), "--no-document")
    Dir.chdir(directory) do
      code = 'require "forme_pdf"; pdf = FormePDF.render_html("<h1>Installed gem</h1>"); abort "Invalid PDF" unless pdf.start_with?("%PDF-"); puts Gem.loaded_specs.fetch("forme-ruby").platform'
      abort "Installed gem smoke failed" unless system(env, RbConfig.ruby, "-e", code)
    end
  end
end
