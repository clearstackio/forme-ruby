#!/usr/bin/env bash
set -euo pipefail
# UBI 8 owns the oldest supported glibc; never compile on the newer host.
test "$(uname -m)" = x86_64
ldd --version
export CARGO_HOME=/tmp/forme-cargo
export RUSTUP_HOME=/tmp/forme-rustup
curl -4 --fail --silent --show-error -o /tmp/rustup-init \
  https://static.rust-lang.org/rustup/archive/1.29.1/x86_64-unknown-linux-gnu/rustup-init
echo "dda7234360b7f578ca8b0ddcb80145646fa61a67c1720a5abc7051b35c9fcb71  /tmp/rustup-init" | sha256sum -c -
chmod +x /tmp/rustup-init
/tmp/rustup-init -y --no-modify-path --profile minimal --default-toolchain 1.94.0
export PATH="$CARGO_HOME/bin:$PATH"
export RUSTFLAGS="-C target-cpu=x86-64"
gem install bundler --version 4.0.23 --no-document
bundle _4.0.23_ install
bundle _4.0.23_ exec rake compile
cargo test --release --locked --manifest-path ext/forme_pdf/Cargo.toml
bundle _4.0.23_ exec rspec
ruby script/ci/check-linux-abi.rb
ruby script/notices.rb
bundle _4.0.23_ exec rake 'package[source]'
bundle _4.0.23_ exec rake 'package[native]'
ruby script/test_packages.rb
