#!/usr/bin/env bash
set -euo pipefail
case "${1:?distribution required}" in
  rhel8|rhel9|rhel10) ;; # Official Red Hat UBI images already provide Ruby 3.3.
  ubuntu24|ubuntu26)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y --no-install-recommends ruby ca-certificates
    ;;
  arch)
    pacman -Syu --noconfirm ruby ca-certificates
    ;;
  *) echo "Unknown distribution" >&2; exit 1 ;;
esac
ruby -e 'abort "Ruby 3.2+ required" if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("3.2")'
if command -v cargo >/dev/null; then
  echo "Compatibility image must not contain Rust/Cargo" >&2
  exit 1
fi
# Keep gems shipped by the distro Ruby (UBI JSON is not marked as a default gem).
distribution_gem_path="$(ruby -e 'puts Gem.path.join(File::PATH_SEPARATOR)')"
ruby -e 'abort "Image already contains forme-ruby" unless Gem::Specification.find_all_by_name("forme-ruby").empty?'
export GEM_HOME=/tmp/forme-installed
export GEM_PATH="$GEM_HOME:$distribution_gem_path"
unset RUBYOPT BUNDLE_GEMFILE
# Dependencies may install normally; forme-ruby itself must be the native artifact.
# Override Arch's user-install default without --install-dir, which forces
# reinstallation of existing dependencies and can require a JSON compiler.
gem install /work/pkg/*-x86_64-linux-gnu.gem --no-user-install --no-document
ruby /work/script/ci/installed-smoke.rb
