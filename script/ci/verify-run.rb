# frozen_string_literal: true

require "json"

run = JSON.parse(File.read(ARGV.fetch(0)))
valid = run["conclusion"] == "success" &&
  run["head_sha"] == ENV.fetch("GITHUB_SHA") &&
  run["head_branch"] == "main" &&
  run.dig("head_repository", "full_name") == ENV.fetch("GITHUB_REPOSITORY") &&
  %w[push workflow_dispatch schedule].include?(run["event"]) &&
  run["path"] == ".github/workflows/ci.yml"
abort "Require successful CI for this exact main-branch commit in this repository" unless valid
