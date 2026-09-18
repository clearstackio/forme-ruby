#!/usr/bin/env bash
set -euo pipefail
# UBI 8 owns the oldest supported glibc; never compile on the newer host.
test "$(uname -m)" = x86_64
ldd --version
export CARGO_HOME=/tmp/forme-cargo
export RUSTUP_HOME=/tmp/forme-rustup
curl -4 --fail --silent --show-error https://sh.rustup.rs -o /tmp/forme-rustup.sh
bash /tmp/forme-rustup.sh -y --profile minimal --default-toolchain 1.94.0
export PATH="$CARGO_HOME/bin:$PATH"
export RUSTFLAGS="-C target-cpu=x86-64"
gem install bundler --version 4.0.14 --no-document
bundle _4.0.14_ install
bundle _4.0.14_ exec rake compile
cargo test --release --locked --manifest-path ext/forme_pdf/Cargo.toml
bundle _4.0.14_ exec rspec
ruby script/ci/check-linux-abi.rb
ruby script/notices.rb
bundle _4.0.14_ exec rake 'package[source]'
bundle _4.0.14_ exec rake 'package[native]'
ruby script/test_packages.rb
