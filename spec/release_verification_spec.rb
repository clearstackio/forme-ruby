# frozen_string_literal: true

require "json"
require "open3"
require "tempfile"
require "tmpdir"
require_relative "../lib/forme_pdf/version"

RSpec.describe "Release CI provenance validation" do
  let(:script) { File.expand_path("../script/ci/verify-run.rb", __dir__) }
  let(:run) do
    {"conclusion" => "success", "head_sha" => "reviewed-sha", "head_branch" => "main",
     "head_repository" => {"full_name" => "clearstackio/forme-ruby"},
     "event" => "push", "path" => ".github/workflows/ci.yml"}
  end

  def validate(run)
    Tempfile.create(["forme-run", ".json"]) do |file|
      file.write(JSON.generate(run))
      file.flush
      Open3.capture3({"GITHUB_SHA" => "reviewed-sha", "GITHUB_REPOSITORY" => "clearstackio/forme-ruby"},
        RbConfig.ruby, script, file.path).last.success?
    end
  end

  it "accepts successful CI on the exact main commit" do
    expect(validate(run)).to be(true)
  end

  it "rejects stale, failed, fork, pull-request and unrelated workflow evidence" do
    [{"head_sha" => "old-sha"}, {"conclusion" => "failure"}, {"head_branch" => "feature"},
      {"head_repository" => {"full_name" => "fork/forme-ruby"}},
      {"event" => "pull_request"}, {"path" => ".github/workflows/release.yml"}].each do |change|
      expect(validate(run.merge(change))).to be(false), change.inspect
    end
  end

  it "rejects an empty release package directory" do
    verifier = File.expand_path("../script/ci/verify-release.rb", __dir__)
    Dir.mktmpdir("forme-release") do |directory|
      _, error, status = Open3.capture3(RbConfig.ruby, verifier, chdir: directory)
      expect(status.success?).to be(false)
      expect(error).to include("Expected exactly three packages")
    end
  end
end

RSpec.describe "Release package inventory validation" do
  let(:verifier) { File.expand_path("../script/ci/verify-release.rb", __dir__) }

  def verify_packages(platforms, version: FormePDF::VERSION, include_license: true)
    Dir.mktmpdir("forme-package-inventory") do |directory|
      # Build synthetic archives in a subprocess; never alter the real pkg directory.
      builder = <<~'RUBY'
        require "rubygems/package"
        require "fileutils"
        FileUtils.mkdir_p("pkg")
        ARGV.each_with_index do |platform, index|
          files = %w[README.md NOTICE THIRD_PARTY_LICENSES.txt]
          files << "LICENSE" if ENV.fetch("INCLUDE_LICENSE") == "true"
          extension = platform == "ruby" ? "ext/forme_pdf/extconf.rb" : "lib/forme_pdf/native/libforme_pdf_native.#{platform == "arm64-darwin" ? "dylib" : "so"}"
          files << extension
          files.each { |file| FileUtils.mkdir_p(File.dirname(file)); File.write(file, "fixture") }
          spec = Gem::Specification.new do |gem|
            gem.name = "forme-ruby"
            gem.version = ENV.fetch("FIXTURE_VERSION")
            gem.summary = "Synthetic package fixture"
            gem.authors = ["Fixture"]
            gem.files = files
            gem.platform = platform
            gem.extensions = platform == "ruby" ? [extension] : []
          end
          file = Gem::Package.build(spec)
          FileUtils.mv(file, "pkg/#{index}.gem")
        end
      RUBY
      _, error, status = Open3.capture3({"FIXTURE_VERSION" => version, "INCLUDE_LICENSE" => include_license.to_s},
        RbConfig.ruby, "-e", builder, *platforms, chdir: directory)
      raise error unless status.success?
      Open3.capture3(RbConfig.ruby, verifier, chdir: directory)
    end
  end

  it "accepts the exact source and two native platforms" do
    _, error, status = verify_packages(%w[ruby arm64-darwin x86_64-linux-gnu])
    expect(status.success?).to be(true), error
  end

  it "rejects duplicate platforms" do
    _, error, status = verify_packages(%w[ruby arm64-darwin arm64-darwin])
    expect(status.success?).to be(false)
    expect(error).to include("Unexpected or duplicate platform")
  end

  it "rejects packages from another version" do
    _, error, status = verify_packages(%w[ruby arm64-darwin x86_64-linux-gnu], version: "9.9.9")
    expect(status.success?).to be(false)
    expect(error).to include("Unexpected name or version")
  end

  it "rejects packages without the license" do
    _, error, status = verify_packages(%w[ruby arm64-darwin x86_64-linux-gnu], include_license: false)
    expect(status.success?).to be(false)
    expect(error).to include("Missing LICENSE")
  end
end
